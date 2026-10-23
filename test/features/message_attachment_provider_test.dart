import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/data/models/chat_upload_model.dart';
import 'package:sukientotapp/data/models/message_model.dart';
import 'package:sukientotapp/data/providers/common/message_provider.dart';

class _Api extends Fake implements ApiService {
  _Api(this.dio);
  @override
  final Dio dio;
}

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];
  int status = 200;
  String? errorBody;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    await requestStream?.drain<void>();
    return ResponseBody.fromString(
      errorBody ??
          jsonEncode(<String, Object>{
            'success': true,
            'message': <String, Object>{
              'id': 99,
              'thread_id': 27,
              'user_id': 7,
              'type': 'file',
              'body': 'quote',
              'user': <String, Object>{'id': 7, 'name': 'Partner'},
            },
          }),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[
          errorBody == null ? 'application/json' : 'text/html',
        ],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory directory;
  late File file;
  late Dio dio;
  late _Adapter adapter;
  late MessageProvider provider;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('chat-provider-test-');
    file = await File(
      '${directory.path}/quote.pdf',
    ).writeAsString('%PDF-sample');
    adapter = _Adapter();
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.example/api',
        headers: <String, String>{'Content-Type': 'application/json'},
      ),
    )..httpClientAdapter = adapter;
    provider = MessageProvider(_Api(dio));
  });
  tearDown(() async {
    dio.close(force: true);
    await directory.delete(recursive: true);
  });

  Future<MessageModel> send(ChatAttachmentType type) => provider.sendAttachment(
    threadId: '27',
    attachment: ChatAttachmentSelection(
      type: type,
      path: file.path,
      name: type == ChatAttachmentType.file ? 'quote.pdf' : 'clip.mp4',
      size: 11,
    ),
    caption: 'quote',
    clientMessageId: 'd3883200-af92-4c4f-aa83-fd63662158ee',
    currentUserId: 7,
    onProgress: (int _, int total) {},
    cancelToken: CancelToken(),
  );

  for (final ChatAttachmentType type in ChatAttachmentType.values) {
    test('${type.name} sends one binary part with retry disabled', () async {
      final MessageModel result = await send(type);
      final RequestOptions request = adapter.requests.single;
      final FormData form = request.data as FormData;
      expect(request.path, '/chat/threads/27/messages');
      expect(form.files.single.key, type.name);
      expect(
        form.files.single.value.filename,
        type == ChatAttachmentType.file ? 'quote.pdf' : 'clip.mp4',
      );
      expect(Map<String, String>.fromEntries(form.fields), <String, String>{
        'type': type.name,
        'body': 'quote',
        'client_message_id': 'd3883200-af92-4c4f-aa83-fd63662158ee',
      });
      expect(request.disableRetry, isTrue);
      expect(request.sendTimeout, const Duration(minutes: 5));
      expect(request.receiveTimeout, const Duration(seconds: 60));
      expect(request.contentType, startsWith('multipart/form-data; boundary='));
      expect(result.id, 99);
      expect(result.sender, 'Partner');
    });
  }
  test('retry recreates consumed multipart streams', () async {
    await send(ChatAttachmentType.file);
    await send(ChatAttachmentType.file);
    expect(
      identical(adapter.requests.first.data, adapter.requests.last.data),
      isFalse,
    );
    expect((adapter.requests.last.data as FormData).isFinalized, isTrue);
  });
  test('HTML 413 does not assume a JSON error envelope', () async {
    adapter.status = 413;
    adapter.errorBody = '<html>Request too large</html>';
    await expectLater(
      send(ChatAttachmentType.file),
      throwsA(
        isA<ChatApiException>().having(
          (ChatApiException error) => error.message,
          'message',
          'chat_upload_too_large',
        ),
      ),
    );
  });
  test('validation prefers the file field over the summary', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions request, RequestInterceptorHandler handler) {
          handler.reject(
            DioException(
              requestOptions: request,
              response: Response<Object>(
                requestOptions: request,
                statusCode: 422,
                data: <String, Object>{
                  'message': 'Summary',
                  'errors': <String, Object>{
                    'file': <String>['MIME rejected'],
                  },
                },
              ),
            ),
          );
        },
      ),
    );
    await expectLater(
      send(ChatAttachmentType.file),
      throwsA(
        isA<ChatApiException>().having(
          (ChatApiException error) => error.message,
          'message',
          'MIME rejected',
        ),
      ),
    );
  });
}
