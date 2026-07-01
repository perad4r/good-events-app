import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/message_model.dart'; // Correct import
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isFirst;

  const ChatBubble({super.key, required this.message, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    final isSender = message.isSender;
    final isImageMessage = message.type == 'image';
    return Padding(
      padding: EdgeInsets.fromLTRB(12, isFirst ? 12 : 2, 12, 2),
      child: Column(
        crossAxisAlignment: isSender
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isSender)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 3),
              child: Text(
                message.sender,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: isSender
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isSender)
                Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 2),
                  child: Text(
                    message.time,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isImageMessage ? 0 : 14,
                    vertical: isImageMessage ? 0 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: isImageMessage
                        ? Colors.transparent
                        : isSender
                            ? AppColors.primary
                            : Colors.white,
                    borderRadius: isImageMessage
                        ? null
                        : BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isSender ? 18 : 4),
                            bottomRight: Radius.circular(isSender ? 4 : 18),
                          ),
                    boxShadow: isImageMessage
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: _BubbleContent(message: message, isSender: isSender),
                ),
              ),
              if (!isSender)
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 2),
                  child: Text(
                    message.time,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({required this.message, required this.isSender});

  final MessageModel message;
  final bool isSender;

  @override
  Widget build(BuildContext context) {
    if (message.type == 'image' && message.attachments.isNotEmpty) {
      return _ImageMessageContent(message: message, isSender: isSender);
    }

    if (message.type == 'location' && message.location != null) {
      return _LocationMessageContent(message: message, isSender: isSender);
    }

    return _LinkifiedMessageText(
      text: message.text.isEmpty ? message.previewText : message.text,
      style: TextStyle(
        color: isSender ? Colors.white : const Color(0xFF1F2937),
        fontSize: 14,
        height: 1.45,
      ),
    );
  }
}

class _ImageMessageContent extends StatelessWidget {
  const _ImageMessageContent({required this.message, required this.isSender});

  final MessageModel message;
  final bool isSender;

  @override
  Widget build(BuildContext context) {
    final attachments = message.attachments
        .where(
          (attachment) =>
              attachment.url.isNotEmpty || attachment.localPath.isNotEmpty,
        )
        .toList();
    if (attachments.isEmpty) {
      return _LinkifiedMessageText(
        text: message.previewText,
        style: TextStyle(
          color: isSender ? Colors.white : const Color(0xFF1F2937),
          fontSize: 14,
          height: 1.45,
        ),
      );
    }

    final visibleAttachments = attachments.take(4).toList();
    final tileSize = attachments.length == 1 ? 190.0 : 92.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: visibleAttachments.asMap().entries.map((entry) {
            final index = entry.key;
            final attachment = entry.value;
            final isLastVisible =
                attachments.length > 4 && attachment == visibleAttachments.last;
            return GestureDetector(
              onTap: () => _openImageViewer(context, attachments, index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    _MessageImageTile(
                      attachment: attachment,
                      size: tileSize,
                    ),
                    if (isLastVisible)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          child: Center(
                            child: Text(
                              '+${attachments.length - 4}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (message.text.isNotEmpty && message.text != message.previewText) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _LinkifiedMessageText(
              text: message.text,
              style: TextStyle(
                color: isSender ? Colors.white : const Color(0xFF1F2937),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openImageViewer(
    BuildContext context,
    List<MessageAttachmentModel> attachments,
    int initialIndex,
  ) {
    Get.to<void>(
      () => _ChatImageViewer(
        attachments: attachments,
        initialIndex: initialIndex,
      ),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 180),
    );
  }
}

class _LinkifiedMessageText extends StatefulWidget {
  const _LinkifiedMessageText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_LinkifiedMessageText> createState() => _LinkifiedMessageTextState();
}

class _LinkifiedMessageTextState extends State<_LinkifiedMessageText> {
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  static final RegExp _urlRegExp = RegExp(
    r'((https?:\/\/)?([\w-]+\.)+[\w-]{2,}(\/[^\s]*)?)',
    caseSensitive: false,
  );

  @override
  void didUpdateWidget(covariant _LinkifiedMessageText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _disposeRecognizers();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final spans = <InlineSpan>[];
    int currentIndex = 0;

    for (final match in _urlRegExp.allMatches(widget.text)) {
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(text: widget.text.substring(currentIndex, match.start)),
        );
      }

      final rawMatch = widget.text.substring(match.start, match.end);
      final trimmed = _trimTrailingPunctuation(rawMatch);
      final trailing = rawMatch.substring(trimmed.length);
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _openUrl(trimmed);
      _recognizers.add(recognizer);

      spans.add(
        TextSpan(
          text: trimmed,
          style: widget.style.copyWith(
            color: _linkColor(widget.style.color),
            decoration: TextDecoration.underline,
            decorationColor: _linkColor(widget.style.color),
          ),
          recognizer: recognizer,
        ),
      );

      if (trailing.isNotEmpty) {
        spans.add(TextSpan(text: trailing));
      }
      currentIndex = match.end;
    }

    if (currentIndex < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(currentIndex)));
    }

    return RichText(
      text: TextSpan(style: widget.style, children: spans),
    );
  }

  String _trimTrailingPunctuation(String value) {
    return value.replaceFirst(RegExp(r'[.,;:!?)]*$'), '');
  }

  Color _linkColor(Color? baseColor) {
    if (baseColor == Colors.white) return Colors.white;
    return AppColors.primary;
  }

  Future<void> _openUrl(String value) async {
    final normalized = value.startsWith(
      RegExp(r'https?:\/\/', caseSensitive: false),
    )
        ? value
        : 'https://$value';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }
}

class _MessageImageTile extends StatelessWidget {
  const _MessageImageTile({required this.attachment, required this.size});

  final MessageAttachmentModel attachment;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (attachment.localPath.isNotEmpty && attachment.url.isEmpty) {
      return Image.file(
        File(attachment.localPath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _ImageErrorTile(size: size);
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: attachment.url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: size,
        height: size,
        color: const Color(0xFFE5E7EB),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => _ImageErrorTile(size: size),
    );
  }
}

class _ImageErrorTile extends StatelessWidget {
  const _ImageErrorTile({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFE5E7EB),
      child: const Icon(Icons.broken_image_outlined),
    );
  }
}

class _ChatImageViewer extends StatefulWidget {
  const _ChatImageViewer({
    required this.attachments,
    required this.initialIndex,
  });

  final List<MessageAttachmentModel> attachments;
  final int initialIndex;

  @override
  State<_ChatImageViewer> createState() => _ChatImageViewerState();
}

class _ChatImageViewerState extends State<_ChatImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.attachments.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: _FullImage(attachment: widget.attachments[index]),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Get.back<void>(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            if (widget.attachments.length > 1)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/${widget.attachments.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FullImage extends StatelessWidget {
  const _FullImage({required this.attachment});

  final MessageAttachmentModel attachment;

  @override
  Widget build(BuildContext context) {
    if (attachment.localPath.isNotEmpty && attachment.url.isEmpty) {
      return Image.file(
        File(attachment.localPath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.broken_image_outlined,
            color: Colors.white70,
            size: 44,
          );
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: attachment.url,
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (context, url, error) => const Icon(
        Icons.broken_image_outlined,
        color: Colors.white70,
        size: 44,
      ),
    );
  }
}

class _LocationMessageContent extends StatelessWidget {
  const _LocationMessageContent({
    required this.message,
    required this.isSender,
  });

  final MessageModel message;
  final bool isSender;

  @override
  Widget build(BuildContext context) {
    final location = message.location!;
    final title = location.label?.isNotEmpty == true
        ? location.label!
        : 'Vị trí hiện tại';
    final subtitle = location.address?.isNotEmpty == true
        ? location.address!
        : '${location.latitude}, ${location.longitude}';

    return InkWell(
      onTap: () => _openMap(location),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSender
                  ? Colors.white.withValues(alpha: 0.18)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: isSender ? Colors.white : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSender ? Colors.white : const Color(0xFF1F2937),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSender
                        ? Colors.white.withValues(alpha: 0.82)
                        : const Color(0xFF6B7280),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMap(MessageLocationModel location) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
