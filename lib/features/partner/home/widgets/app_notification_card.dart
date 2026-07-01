import 'package:flutter_html/flutter_html.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/partner/dashboard_model.dart';

class AppNotificationCard extends StatelessWidget {
  final PartnerAppNotification notification;
  final VoidCallback onDismiss;

  const AppNotificationCard({
    super.key,
    required this.notification,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final content = switch (notification.type) {
      'image_only' => _ImageOnlyNotification(
        notification: notification,
        onDismiss: onDismiss,
      ),
      'text_and_image' => _TextAndImageNotification(
        notification: notification,
        onDismiss: onDismiss,
      ),
      _ => _TextOnlyNotification(
        notification: notification,
        onDismiss: onDismiss,
      ),
    };

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: SingleChildScrollView(child: content),
      ),
    );
  }
}

class _ImageOnlyNotification extends StatelessWidget {
  final PartnerAppNotification notification;
  final VoidCallback onDismiss;

  const _ImageOnlyNotification({
    required this.notification,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl(notification.notificationImageUrl);
    if (imageUrl.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          _NotificationImage(
            imageUrl: imageUrl,
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          Positioned(top: 10, right: 10, child: _DismissButton(onDismiss)),
        ],
      ),
    );
  }
}

class _TextOnlyNotification extends StatelessWidget {
  final PartnerAppNotification notification;
  final VoidCallback onDismiss;

  const _TextOnlyNotification({
    required this.notification,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!notification.hasText) return const SizedBox.shrink();

    return Container(
      decoration: _cardDecoration(
        color: Colors.white,
        borderColor: AppColors.primary.withValues(alpha: 0.22),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 58, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(FIcons.bell, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: _NotificationText(notification: notification)),
              ],
            ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: _DismissButton(
              onDismiss,
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextAndImageNotification extends StatelessWidget {
  final PartnerAppNotification notification;
  final VoidCallback onDismiss;

  const _TextAndImageNotification({
    required this.notification,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl(notification.imageUrl);
    if (imageUrl.isEmpty && !notification.hasText) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            Stack(
              children: [
                _NotificationImage(
                  imageUrl: imageUrl,
                  maxHeight: MediaQuery.of(context).size.height * 0.42,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _DismissButton(onDismiss),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 10),
                child: _DismissButton(onDismiss),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: _NotificationText(notification: notification),
          ),
        ],
      ),
    );
  }
}

class _NotificationText extends StatelessWidget {
  final PartnerAppNotification notification;

  const _NotificationText({required this.notification});

  @override
  Widget build(BuildContext context) {
    final title = notification.title?.trim();
    final content = notification.content?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title.isNotEmpty)
          Text(
            title,
            style: context.typography.base.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        if (title != null &&
            title.isNotEmpty &&
            content != null &&
            content.isNotEmpty)
          const SizedBox(height: 6),
        if (content != null && content.isNotEmpty)
          Html(
            data: content,
            style: {
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                color: const Color(0xFF4B5563),
                fontSize: FontSize(14),
                lineHeight: LineHeight(1.45),
              ),
              'p': Style(margin: Margins.only(bottom: 8)),
              'ul': Style(margin: Margins.only(bottom: 8)),
              'ol': Style(margin: Margins.only(bottom: 8)),
            },
          ),
      ],
    );
  }
}

class _NotificationImage extends StatelessWidget {
  final String imageUrl;
  final double maxHeight;

  const _NotificationImage({required this.imageUrl, required this.maxHeight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          imageBuilder: (context, imageProvider) => Image(
            image: imageProvider,
            width: double.infinity,
            fit: BoxFit.contain,
          ),
          placeholder: (context, url) => Container(
            height: 180,
            color: const Color(0xFFF3F4F6),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 180,
            color: const Color(0xFFF3F4F6),
            alignment: Alignment.center,
            child: Icon(
              FIcons.imageOff,
              color: context.fTheme.colors.mutedForeground,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _DismissButton extends StatelessWidget {
  final VoidCallback onDismiss;
  final Color foregroundColor;

  const _DismissButton(this.onDismiss, {this.foregroundColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return FTappable(
      onPress: onDismiss,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: foregroundColor == Colors.white
              ? Colors.black.withValues(alpha: 0.35)
              : Colors.white,
          shape: BoxShape.circle,
          border: foregroundColor == Colors.white
              ? null
              : Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(FIcons.x, size: 16, color: foregroundColor),
      ),
    );
  }
}

BoxDecoration _cardDecoration({Color? color, Color? borderColor}) {
  return BoxDecoration(
    color: color ?? Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: borderColor ?? Colors.black.withValues(alpha: 0.05),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 14,
        offset: const Offset(0, 5),
      ),
    ],
  );
}

String _resolveImageUrl(String? url) {
  final value = url?.trim() ?? '';
  if (value.isEmpty) return '';
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  final baseUrl = ApiService.baseUrl.replaceAll(RegExp(r'/+$'), '');
  final path = value.replaceAll(RegExp(r'^/+'), '');
  if (baseUrl.isEmpty) return path;

  return '$baseUrl/$path';
}
