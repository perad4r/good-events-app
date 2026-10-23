class ChatApiException implements Exception {
  const ChatApiException({required this.message, this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
