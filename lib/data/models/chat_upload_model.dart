enum ChatAttachmentType { file, video }

enum ChatUploadStatus { sending, failed }

class ChatAttachmentSelection {
  const ChatAttachmentSelection({
    required this.type,
    required this.path,
    required this.name,
    required this.size,
  });

  final ChatAttachmentType type;
  final String path;
  final String name;
  final int size;

  static const Set<String> fileExtensions = {
    'zip',
    'rar',
    '7z',
    'pdf',
    'txt',
    'csv',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'psd',
    'psb',
    'ai',
    'eps',
    'indd',
    'idml',
    'aep',
    'prproj',
    'xd',
  };
  static const Set<String> videoExtensions = {'mp4', 'mov', 'm4v', 'webm'};

  /// Returns a translation key; the server remains authoritative about MIME.
  String? validate() {
    final String extension = name.split('.').last.toLowerCase();
    final Set<String> extensions = type == ChatAttachmentType.file
        ? fileExtensions
        : videoExtensions;
    if (!name.contains('.') || !extensions.contains(extension)) {
      return 'chat_attachment_format_error';
    }
    final int limit = type == ChatAttachmentType.file ? 20971520 : 52428800;
    if (size > limit) {
      return type == ChatAttachmentType.file
          ? 'chat_file_size_error'
          : 'chat_video_size_error';
    }
    if (size <= 0) return 'chat_attachment_empty';
    return null;
  }

  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ChatUploadTask {
  ChatUploadTask({
    required this.clientMessageId,
    required this.threadId,
    required this.attachment,
    required this.caption,
  });

  final String clientMessageId;
  final String threadId;
  final ChatAttachmentSelection attachment;
  final String caption;
  ChatUploadStatus status = ChatUploadStatus.sending;
  double progress = 0;
  String? error;
}
