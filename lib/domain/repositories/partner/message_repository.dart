import 'package:image_picker/image_picker.dart';

abstract class MessageRepository {
  Future<Map<String, dynamic>> getThreads({
    required int page,
    String? side,
    String? search,
  });

  Future<Map<String, dynamic>> getMessages({
    required String threadId,
    required int page,
  });

  Future<void> sendMessage({
    required String threadId,
    required String type,
    String? body,
    List<XFile>? images,
    Map<String, dynamic>? location,
  });
}
