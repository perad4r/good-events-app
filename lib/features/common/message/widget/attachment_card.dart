import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/core/utils/phone_number_censor.dart';
import 'package:sukientotapp/core/services/chat_media_service.dart';
import 'package:sukientotapp/data/models/chat_upload_model.dart';
import 'package:sukientotapp/data/models/message_model.dart';
import '../controller.dart';
import '../video_screen.dart';
import 'cached_message_avatar.dart';
import 'message_timestamp.dart';

class ChatAttachmentBubble extends StatefulWidget {
  const ChatAttachmentBubble({super.key, required this.message});
  final MessageModel message;

  @override
  State<ChatAttachmentBubble> createState() => _ChatAttachmentBubbleState();
}

class _ChatAttachmentBubbleState extends State<ChatAttachmentBubble> {
  bool _opening = false;
  double? _progress;

  Future<void> _open() async {
    if (_opening || widget.message.attachments.isEmpty) return;
    final MessageAttachmentModel attachment = widget.message.attachments.first;
    final ChatMediaService service = Get.find<MessageController>().mediaService;
    if (widget.message.type == 'video') {
      await Get.to<void>(
        () => ChatVideoScreen(attachment: attachment, mediaService: service),
      );
      return;
    }
    setState(() => _opening = true);
    try {
      await service.openAttachment(
        attachment,
        onProgress: (int received, int total) {
          if (mounted) {
            setState(
              () => _progress = total > 0
                  ? (received / total).clamp(0.0, 1.0)
                  : null,
            );
          }
        },
      );
    } catch (error) {
      if (mounted) {
        AppSnackbar.showError(
          message: error is ChatMediaException
              ? error.key.tr
              : 'chat_open_failed'.tr,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
          _progress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final MessageModel message = widget.message;
    final String? senderAvatar = Get.isRegistered<MessageController>()
        ? Get.find<MessageController>().resolveSenderAvatar(message)
        : message.senderAvatar;
    final MessageAttachmentModel? attachment = message.attachments.firstOrNull;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        mainAxisAlignment: message.isSender
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (!message.isSender) ...<Widget>[
            CachedMessageAvatar(imageUrl: senderAvatar),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * .72,
              ),
              child: FCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(message.sender, style: context.typography.xs),
                    const SizedBox(height: 8),
                    AttachmentInfo(
                      name:
                          attachment?.name ?? 'chat_attachment_unavailable'.tr,
                      size: attachment?.size ?? 0,
                      video: message.type == 'video',
                    ),
                    if (message.text.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        PhoneNumberCensor.censor(message.text),
                        style: context.typography.sm,
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (_opening) ...<Widget>[
                      if (_progress == null)
                        const FProgress()
                      else
                        FDeterminateProgress(value: _progress!),
                      const SizedBox(height: 8),
                    ],
                    FButton(
                      onPress: attachment == null || _opening ? null : _open,
                      child: Text(
                        (_opening
                                ? 'chat_downloading'
                                : message.type == 'video'
                                ? 'chat_watch_video'
                                : 'chat_open_file')
                            .tr,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MessageTimestamp(
                      message: message,
                      style: context.typography.xs,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (message.isSender) ...<Widget>[
            const SizedBox(width: 8),
            CachedMessageAvatar(imageUrl: senderAvatar),
          ],
        ],
      ),
    );
  }
}

class AttachmentInfo extends StatelessWidget {
  const AttachmentInfo({
    super.key,
    required this.name,
    required this.size,
    required this.video,
  });
  final String name;
  final int size;
  final bool video;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Icon(
        video ? FIcons.play : FIcons.file,
        color: context.fTheme.colors.primary,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.typography.sm,
            ),
            Text(
              '${name.contains('.') ? name.split('.').last.toUpperCase() : ''} · ${ChatAttachmentSelection.formatSize(size)}',
              style: context.typography.xs,
            ),
          ],
        ),
      ),
    ],
  );
}

class ChatUploadBubble extends StatelessWidget {
  const ChatUploadBubble({
    super.key,
    required this.task,
    required this.controller,
    required this.busy,
  });
  final ChatUploadTask task;
  final MessageController controller;
  final bool busy;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Flexible(
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * .72,
            child: FCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AttachmentInfo(
                    name: task.attachment.name,
                    size: task.attachment.size,
                    video: task.attachment.type == ChatAttachmentType.video,
                  ),
                  if (task.caption.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(task.caption, style: context.typography.sm),
                    ),
                  const SizedBox(height: 8),
                  if (task.status == ChatUploadStatus.sending) ...<Widget>[
                    FDeterminateProgress(value: task.progress),
                    Text(
                      '${'chat_uploading'.tr} ${(task.progress * 100).round()}%',
                      style: context.typography.xs,
                    ),
                  ] else ...<Widget>[
                    Text(
                      task.error ?? 'chat_upload_failed'.tr,
                      style: context.typography.xs.copyWith(
                        color: context.fTheme.colors.destructive,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FButton(
                      onPress: busy
                          ? null
                          : () => controller.retryAttachment(task),
                      child: Text('chat_retry'.tr),
                    ),
                    const SizedBox(height: 6),
                    FButton(
                      onPress: () => controller.discardAttachment(task),
                      child: Text('chat_discard'.tr),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        CachedMessageAvatar(imageUrl: controller.uploadSenderAvatar),
      ],
    ),
  );
}
