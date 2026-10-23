import 'dart:io';
import 'dart:math';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sukientotapp/data/models/chat_upload_model.dart';
import 'package:sukientotapp/data/models/message_model.dart';

class ChatMediaException implements Exception {
  const ChatMediaException(this.key);
  final String key;
  @override
  String toString() => key;
}

/// Session-scoped media storage. Public media never uses the API Dio/token.
class ChatMediaService {
  ChatMediaService({
    Dio? dio,
    Future<Directory> Function()? temporaryDirectory,
    Future<OpenResult> Function(String path, String? mime)? openFile,
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _openFile = openFile ?? _openNative,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(minutes: 2),
             ),
           );

  final Dio _dio;
  final Future<Directory> Function() _temporaryDirectory;
  final Future<OpenResult> Function(String path, String? mime) _openFile;

  static Future<OpenResult> _openNative(String path, String? mime) =>
      OpenFilex.open(path, type: mime);
  Future<Directory>? _directory;
  final Set<CancelToken> _downloads = <CancelToken>{};
  final Set<String> _opening = <String>{};
  bool _disposed = false;
  final Set<Future<void>> _operations = <Future<void>>{};
  Future<void>? _disposing;

  Future<T> _track<T>(Future<T> Function() operation) async {
    if (_disposed) {
      throw const ChatMediaException('chat_attachment_unavailable');
    }
    final Completer<void> completion = Completer<void>();
    _operations.add(completion.future);
    try {
      return await operation();
    } finally {
      completion.complete();
      _operations.remove(completion.future);
    }
  }

  Future<Directory> _root() async {
    if (_disposed) {
      throw const ChatMediaException('chat_attachment_unavailable');
    }
    return _directory ??= _createDirectory();
  }

  Future<Directory> _createDirectory() async {
    final Directory temporary = await _temporaryDirectory();
    final String suffix =
        '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
    return Directory('${temporary.path}/chat-media-$suffix').create();
  }

  static String safeName(String name) {
    final String leaf = name
        .split(RegExp(r'[/\\]'))
        .last
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_')
        .replaceAll(RegExp(r'[. ]+$'), '');
    if (leaf.isEmpty || leaf == '.' || leaf == '..') return 'attachment';
    // Keep the extension while avoiding filesystem component length limits.
    return leaf.length <= 120 ? leaf : leaf.substring(leaf.length - 120);
  }

  Future<ChatAttachmentSelection> stage({
    required XFile file,
    required ChatAttachmentType type,
    required String id,
  }) => _track(() => _stage(file: file, type: type, id: id));

  Future<ChatAttachmentSelection> _stage({
    required XFile file,
    required ChatAttachmentType type,
    required String id,
  }) async {
    final ChatAttachmentSelection selection = ChatAttachmentSelection(
      type: type,
      path: file.path,
      name: file.name,
      size: await file.length(),
    );
    final String? error = selection.validate();
    if (error != null) throw ChatMediaException(error);
    final Directory root = await _root();
    final String path = '${root.path}/$id-${safeName(selection.name)}';
    await file.saveTo(path);
    if (_disposed) {
      await removeLocal(path);
      throw const ChatMediaException('chat_attachment_unavailable');
    }
    return ChatAttachmentSelection(
      type: type,
      path: path,
      name: selection.name,
      size: selection.size,
    );
  }

  Future<void> removeLocal(String path) async {
    final Future<Directory>? pending = _directory;
    if (pending == null) return;
    final Directory root = await pending;
    final String prefix = '${root.absolute.path}${Platform.pathSeparator}';
    final File file = File(path);
    // Only remove files created by this service, never the original picker file.
    if (!file.absolute.path.startsWith(prefix) &&
        !file.absolute.path
            .replaceAll('\\', '/')
            .startsWith('${root.absolute.path.replaceAll('\\', '/')}/')) {
      return;
    }
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // A temporary file can already have been removed by the OS/session cleanup.
    }
  }

  Future<void> openAttachment(
    MessageAttachmentModel attachment, {
    required void Function(int received, int total) onProgress,
  }) => _track(() => _openAttachment(attachment, onProgress: onProgress));

  Future<void> _openAttachment(
    MessageAttachmentModel attachment, {
    required void Function(int received, int total) onProgress,
  }) async {
    final String key =
        '${attachment.id}-${attachment.url}-${attachment.localPath}';
    if (!_opening.add(key)) return;
    CancelToken? token;
    File? partial;
    try {
      final Directory root = await _root();
      String path = attachment.localPath;
      if (path.isEmpty || !await File(path).exists()) {
        final Uri? uri = Uri.tryParse(attachment.url);
        if (uri == null ||
            !uri.hasAuthority ||
            (uri.scheme != 'https' && uri.scheme != 'http')) {
          throw const ChatMediaException('chat_attachment_unavailable');
        }
        // Include the complete URL in the stable session cache key.
        final String cacheKey = urlFingerprint(attachment.url);
        final Directory folder = await Directory(
          '${root.path}/download-${attachment.id ?? 0}-$cacheKey',
        ).create();
        path =
            '${folder.path}/${safeName(attachment.name.isEmpty ? attachment.fileName : attachment.name)}';
        if (!await File(path).exists()) {
          token = CancelToken();
          _downloads.add(token);
          partial = File('$path.part');
          await _dio.download(
            attachment.url,
            partial.path,
            cancelToken: token,
            onReceiveProgress: onProgress,
            options: Options(receiveTimeout: const Duration(minutes: 2)),
          );
          if (_disposed) {
            throw const ChatMediaException('chat_attachment_unavailable');
          }
          await partial.rename(path);
          partial = null;
        }
      }
      if (_disposed) return;
      final OpenResult result = await _openFile(
        path,
        attachment.mimeType.isEmpty ? null : attachment.mimeType,
      );
      if (result.type == ResultType.noAppToOpen) {
        throw const ChatMediaException('chat_no_file_app');
      }
      if (result.type != ResultType.done) {
        throw const ChatMediaException('chat_open_failed');
      }
    } on DioException catch (error) {
      if (_disposed || CancelToken.isCancel(error)) return;
      throw ChatMediaException(
        error.response?.statusCode == 404 || error.response?.statusCode == 410
            ? 'chat_attachment_unavailable'
            : 'chat_download_failed',
      );
    } finally {
      if (token != null) _downloads.remove(token);
      _opening.remove(key);
      if (partial != null) await removeLocal(partial.path);
    }
  }

  static String urlFingerprint(String value) {
    // Deterministic FNV-1a fingerprint, only for local filename isolation.
    int hash = 2166136261;
    for (final int unit in value.codeUnits) {
      hash = ((hash ^ unit) * 16777619) & 0xffffffff;
    }
    return hash.toRadixString(16);
  }

  Future<void> dispose() => _disposing ??= _dispose();

  Future<void> _dispose() async {
    _disposed = true;
    for (final CancelToken token in _downloads.toList()) {
      token.cancel('Session ended');
    }
    _dio.close(force: true);
    await Future.wait(_operations.toList());
    final Future<Directory>? pending = _directory;
    if (pending != null) {
      final Directory root = await pending;
      // This is the unique session directory created above.
      if (await root.exists()) await root.delete(recursive: true);
    }
  }
}
