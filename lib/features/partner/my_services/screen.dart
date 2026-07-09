import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/partner/service_model.dart';
import 'controller.dart';

class MyServicesScreen extends GetView<MyServicesController> {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FScaffold(
          header: FHeader.nested(
            title: Text('my_services'.tr),
            prefixes: [FHeaderAction.back(onPress: () => Get.back())],
          ),
          child: Obx(() {
            if (controller.isLoading.value) {
              return _buildSkeleton();
            }

            return SmartRefresher(
              controller: controller.refreshController,
              enablePullDown: true,
              enablePullUp: false,
              header: const ClassicHeader(),
              onRefresh: controller.onRefresh,
              child: controller.services.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: controller.services.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final service = controller.services[index];
                        return ServiceCard(
                              service: service,
                              onEdit: () => controller.openEditSheet(service),
                              onManageMedia: () =>
                                  controller.openManageMediaSheet(service),
                            )
                            .animate(delay: (index * 100).ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(
                              begin: -0.02,
                              end: 0,
                              curve: Curves.easeOut,
                            );
                      },
                    ),
            );
          }),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            onPressed: () => Get.find<MyServicesController>().openAddSheet(),
            backgroundColor: context.fTheme.colors.primary,
            foregroundColor: context.fTheme.colors.primaryForeground,
            icon: const Icon(FIcons.plus),
            label: Text('add_service'.tr),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const _ServiceCardSkeleton(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: context.fTheme.colors.secondary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Icon(
                  FIcons.briefcase,
                  size: 44,
                  color: context.fTheme.colors.mutedForeground,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'no_services'.tr,
              style: context.typography.lg.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'no_services_desc'.tr,
              style: context.typography.sm.copyWith(
                color: context.fTheme.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton placeholder shown while loading
// ---------------------------------------------------------------------------

class _ServiceCardSkeleton extends StatelessWidget {
  const _ServiceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = context.fTheme.colors.secondary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 22,
                  width: 80,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Service card
// ---------------------------------------------------------------------------

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onEdit;
  final VoidCallback? onManageMedia;

  const ServiceCard({
    super.key,
    required this.service,
    this.onEdit,
    this.onManageMedia,
  });

  Color _accentColor() => switch (service.status) {
    'approved' => const Color(0xFF10B981),
    'rejected' => const Color(0xFFEF4444),
    _ => const Color(0xFFF59E0B),
  };

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left status stripe
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Category icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            FIcons.briefcase,
                            size: 22,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title & badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                service.category,
                                style: context.typography.base.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              StatusBadge(status: service.status),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ServiceActionButton(
                            onPressed: onManageMedia,
                            icon: FIcons.image,
                            label: 'manage_media'.tr,
                            foregroundColor: context.fTheme.colors.primary,
                            backgroundColor: context.fTheme.colors.primary
                                .withValues(alpha: 0.1),
                            borderColor: context.fTheme.colors.primary
                                .withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ServiceActionButton(
                            onPressed: service.isEditable ? onEdit : null,
                            icon: FIcons.pencil,
                            label: 'edit'.tr,
                            foregroundColor: context.fTheme.colors.foreground,
                            backgroundColor: Colors.white,
                            borderColor: service.isEditable
                                ? context.fTheme.colors.border
                                : context.fTheme.colors.border.withValues(
                                    alpha: 0.5,
                                  ),
                            disabledForegroundColor:
                                context.fTheme.colors.mutedForeground,
                            disabledBackgroundColor:
                                context.fTheme.colors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color? disabledForegroundColor;
  final Color? disabledBackgroundColor;

  const _ServiceActionButton({
    this.onPressed,
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
    this.disabledForegroundColor,
    this.disabledBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final effectiveForeground = isDisabled
        ? disabledForegroundColor ?? context.fTheme.colors.mutedForeground
        : foregroundColor;
    final effectiveBackground = isDisabled
        ? disabledBackgroundColor ?? context.fTheme.colors.secondary
        : backgroundColor;

    return Material(
      color: effectiveBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: effectiveForeground),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.xs.copyWith(
                    color: effectiveForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color dotColor;
    final Color textColor;
    final String label;

    switch (status) {
      case 'approved':
        bgColor = const Color(0xFFD1FAE5);
        dotColor = const Color(0xFF10B981);
        textColor = const Color(0xFF065F46);
        label = 'approved'.tr;
      case 'rejected':
        bgColor = const Color(0xFFFEE2E2);
        dotColor = const Color(0xFFEF4444);
        textColor = const Color(0xFF991B1B);
        label = 'rejected'.tr;
      default:
        bgColor = const Color(0xFFFEF3C7);
        dotColor = const Color(0xFFF59E0B);
        textColor = const Color(0xFF92400E);
        label = 'pending'.tr;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: context.typography.xs.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
