part of '../profile_preview.dart';

class ProfilePreviewModal extends StatelessWidget {
  final PublicProfilePreviewModel? profile;
  final String avatarUrl;
  final bool isLoading;
  final String errorMessage;
  final VoidCallback onClose;
  final VoidCallback onRetry;

  const ProfilePreviewModal({
    super.key,
    required this.profile,
    required this.avatarUrl,
    required this.isLoading,
    required this.errorMessage,
    required this.onClose,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.sizeOf(context).width < 768;
    final double maxWidth = isMobile ? MediaQuery.sizeOf(context).width : 960;
    final double maxHeight =
        MediaQuery.sizeOf(context).height * (isMobile ? 0.92 : 0.85);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          minWidth: isMobile ? 0 : 720,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.white,
            child: _buildBody(context, isMobile),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isMobile) {
    if (isLoading) {
      return SizedBox(
        height: 320,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: FTheme.of(context).colors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'loading_profile_preview'.tr,
                style: context.typography.sm.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage.isNotEmpty || profile == null) {
      return SizedBox(
        height: 320,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                const SizedBox(height: 12),
                Text(
                  errorMessage.isNotEmpty
                      ? errorMessage
                      : 'failed_to_load_public_profile'.tr,
                  textAlign: TextAlign.center,
                  style: context.typography.sm.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: FTheme.of(context).colors.primary,
                  ),
                  child: Text('retry'.tr),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final payload = profile!.payload;

    return Column(
      children: [
        _Header(user: payload.user, avatarUrl: avatarUrl, onClose: onClose),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ActionCard(
                  onReportPressed: () {
                    showReportBottomSheet(reportedUserId: payload.user.id);
                  },
                ),
                const SizedBox(height: 16),
                if (isMobile) ...[
                  _QuickStatsCard(quick: payload.quick),
                  const SizedBox(height: 16),
                  _IntroductionCard(payload: payload),
                  const SizedBox(height: 16),
                  _VideoCard(payload: payload),
                  const SizedBox(height: 16),
                  _ReviewsCard(reviews: payload.reviews),
                  const SizedBox(height: 16),
                  _ServicesCard(services: payload.services),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _ContactCard(contact: payload.contact),
                            const SizedBox(height: 16),
                            _QuickStatsCard(quick: payload.quick),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 8,
                        child: Column(
                          children: [
                            _IntroductionCard(payload: payload),
                            const SizedBox(height: 16),
                            _VideoCard(payload: payload),
                            const SizedBox(height: 16),
                            _ReviewsCard(reviews: payload.reviews),
                            const SizedBox(height: 16),
                            _ServicesCard(services: payload.services),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                _GalleryCard(services: payload.services),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
