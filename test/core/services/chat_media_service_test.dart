import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:sukientotapp/core/services/chat_media_service.dart';
import 'package:sukientotapp/data/models/chat_upload_model.dart';
import 'package:sukientotapp/data/models/message_model.dart';

class _Adapter implements HttpClientAdapter {
  int calls = 0;
  int status = 200;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    expect(
      options.headers.keys.map((String key) => key.toLowerCase()),
      isNot(contains('authorization')),
    );
    return ResponseBody.fromBytes(
      <int>[1, 2, 3],
      status,
      headers: <String, List<String>>{
        Headers.contentLengthHeader: <String>['3'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory directory;
  late _Adapter adapter;
  late ChatMediaService service;
  final List<String> opened = <String>[];
  ResultType openResult = ResultType.done;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('chat-media-test-');
    adapter = _Adapter();
    opened.clear();
    openResult = ResultType.done;
    service = ChatMediaService(
      dio: Dio()..httpClientAdapter = adapter,
      temporaryDirectory: () async => directory,
      openFile: (String path, String? mime) async {
        opened.add(path);
        return OpenResult(type: openResult);
      },
    );
  });
  tearDown(() async {
    await service.dispose();
    await directory.delete(recursive: true);
  });

  const MessageAttachmentModel attachment = MessageAttachmentModel(
    id: 42,
    name: '../quote.pdf',
    url: 'https://media.example/uuid.pdf',
    size: 3,
  );
  Future<void> open() =>
      service.openAttachment(attachment, onProgress: (int _, int total) {});

  test(
    'download omits API auth, sanitizes names and reuses complete cache',
    () async {
      await open();
      await open();
      expect(adapter.calls, 1);
      expect(opened, hasLength(2));
      expect(opened.first.replaceAll('\\', '/'), endsWith('/quote.pdf'));
      expect(await File(opened.first).readAsBytes(), <int>[1, 2, 3]);
      expect(
        directory
            .listSync(recursive: true)
            .whereType<File>()
            .where((File file) => file.path.endsWith('.part')),
        isEmpty,
      );
    },
  );
  test('simultaneous opens share one in-flight download', () async {
    await Future.wait(<Future<void>>[open(), open()]);
    expect(adapter.calls, 1);
    expect(opened, hasLength(1));
  });

  test('404 stops downloading and exposes unavailable error', () async {
    adapter.status = 404;
    await expectLater(
      open(),
      throwsA(
        isA<ChatMediaException>().having(
          (ChatMediaException error) => error.key,
          'key',
          'chat_attachment_unavailable',
        ),
      ),
    );
    expect(adapter.calls, 1);
    expect(opened, isEmpty);
  });
  test('missing external app has a specific error', () async {
    openResult = ResultType.noAppToOpen;
    await expectLater(
      open(),
      throwsA(
        isA<ChatMediaException>().having(
          (ChatMediaException error) => error.key,
          'key',
          'chat_no_file_app',
        ),
      ),
    );
  });
  test('staged copy is cleaned without deleting the source', () async {
    final File source = await File(
      '${directory.path}/source.pdf',
    ).writeAsString('sample');
    final ChatAttachmentSelection staged = await service.stage(
      file: XFile(source.path),
      type: ChatAttachmentType.file,
      id: 'selection',
    );
    expect(staged.path, isNot(source.path));
    expect(await File(staged.path).exists(), isTrue);
    await service.dispose();
    expect(await File(staged.path).exists(), isFalse);
    expect(await source.exists(), isTrue);
  });
}
