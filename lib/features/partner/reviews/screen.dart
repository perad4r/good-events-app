import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/partner/partner_review_model.dart';
import 'controller.dart';

class PartnerReviewsScreen extends GetView<PartnerReviewsController> {
  const PartnerReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader.nested(
        title: Text('my_reviews'.tr),
        prefixes: [FHeaderAction.back(onPress: () => Get.back())],
      ),
      child: Obx(() {
        final isInitialLoading =
            controller.isLoading.value && controller.reviews.isEmpty;

        if (isInitialLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty &&
            controller.reviews.isEmpty) {
          return _ErrorState(
            message: controller.errorMessage.value,
            onRetry: () => controller.fetchReviews(refresh: true),
          );
        }

        return SmartRefresher(
          controller: controller.refreshController,
          enablePullDown: true,
          enablePullUp: true,
          header: const ClassicHeader(),
          footer: const ClassicFooter(),
          onRefresh: controller.onRefresh,
          onLoading: controller.onLoading,
          child: controller.reviews.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  itemCount: controller.reviews.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final review = controller.reviews[index];
                    return _ReviewCard(
                      item: review,
                      onTap: () => _showReviewDetailSheet(context, review),
                    );
                  },
                ),
        );
      }),
    );
  }

  void _showReviewDetailSheet(
    BuildContext context,
    PartnerReviewItemModel item,
  ) {
    Get.bottomSheet(
      _ReviewDetailSheet(item: item),
      isScrollControlled: true,
      backgroundColor: context.fTheme.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final PartnerReviewItemModel item;
  final VoidCallback onTap;

  const _ReviewCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final comment = item.review.comment.trim();
    final dateText = _formatDate(item.review.createdAt);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.fTheme.colors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.fTheme.colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.user.name.isNotEmpty
                            ? item.user.name
                            : 'anonymous_user'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.fTheme.colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateText.isNotEmpty ? dateText : item.bill.date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.fTheme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                _RatingPill(rating: item.review.rating),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.bill.category.isNotEmpty ? item.bill.category : 'services'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.fTheme.colors.foreground,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 14,
                  color: context.fTheme.colors.mutedForeground,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    item.bill.code.isNotEmpty ? item.bill.code : '#${item.bill.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.fTheme.colors.mutedForeground,
                    ),
                  ),
                ),
                if (item.review.recommend)
                  _RecommendBadge(text: 'client_recommends'.tr),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                comment,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: context.fTheme.colors.foreground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewDetailSheet extends StatelessWidget {
  final PartnerReviewItemModel item;

  const _ReviewDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final comment = item.review.comment.trim();
    final createdAt = _formatDateTime(item.review.createdAt);
    final eventDate = _formatDate(item.bill.date);

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.fTheme.colors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.user.name.isNotEmpty
                                ? item.user.name
                                : 'anonymous_user'.tr,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: context.fTheme.colors.foreground,
                            ),
                          ),
                          const SizedBox(height: 5),
                          _RatingStars(rating: item.review.rating),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (comment.isNotEmpty)
                  _InfoBlock(
                    icon: Icons.format_quote_rounded,
                    title: 'review_comment'.tr,
                    child: Text(
                      comment,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: context.fTheme.colors.foreground,
                      ),
                    ),
                  )
                else
                  _InfoBlock(
                    icon: Icons.notes_rounded,
                    title: 'review_comment'.tr,
                    child: Text(
                      'no_review_comment'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.fTheme.colors.mutedForeground,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                _InfoBlock(
                  icon: item.review.recommend
                      ? Icons.thumb_up_alt_outlined
                      : Icons.thumb_down_alt_outlined,
                  title: 'recommendation'.tr,
                  child: Text(
                    item.review.recommend
                        ? 'client_recommends'.tr
                        : 'client_not_recommends'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: item.review.recommend
                          ? const Color(0xFF16A34A)
                          : context.fTheme.colors.mutedForeground,
                    ),
                  ),
                ),
                if (item.review.ratings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoBlock(
                    icon: Icons.tune_rounded,
                    title: 'rating_details'.tr,
                    child: Column(
                      children: item.review.ratings.entries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatRatingKey(entry.key),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: context
                                            .fTheme
                                            .colors
                                            .mutedForeground,
                                      ),
                                    ),
                                  ),
                                  _RatingStars(rating: entry.value, size: 14),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _InfoBlock(
                  icon: Icons.event_note_outlined,
                  title: 'basic_info'.tr,
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'payment_order_code'.tr,
                        value: item.bill.code.isNotEmpty
                            ? item.bill.code
                            : '#${item.bill.id}',
                      ),
                      _DetailRow(
                        label: 'services'.tr,
                        value: item.bill.category,
                      ),
                      _DetailRow(
                        label: 'event_type'.tr,
                        value: item.bill.event,
                      ),
                      _DetailRow(
                        label: 'date'.tr,
                        value: eventDate.isNotEmpty ? eventDate : item.bill.date,
                      ),
                      _DetailRow(
                        label: 'revenue'.tr,
                        value: item.bill.finalTotal > 0
                            ? FormatUtils.formatCurrencyToDoule(
                                item.bill.finalTotal,
                              )
                            : '',
                      ),
                      _DetailRow(
                        label: 'review_created_at'.tr,
                        value: createdAt,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _InfoBlock({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.fTheme.colors.muted.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.fTheme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: context.fTheme.colors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.fTheme.colors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: context.fTheme.colors.mutedForeground,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.fTheme.colors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final int rating;

  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF59E0B)),
          const SizedBox(width: 3),
          Text(
            '$rating/5',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  final int rating;
  final double size;

  const _RatingStars({
    required this.rating,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: const Color(0xFFF59E0B),
        );
      }),
    );
  }
}

class _RecommendBadge extends StatelessWidget {
  final String text;

  const _RecommendBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF166534),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      children: [
        SizedBox(height: Get.height * 0.18),
        Icon(
          Icons.rate_review_outlined,
          size: 54,
          color: context.fTheme.colors.mutedForeground.withValues(alpha: 0.55),
        ),
        const SizedBox(height: 14),
        Text(
          'no_partner_reviews'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.fTheme.colors.foreground,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'no_partner_reviews_desc'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: context.fTheme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: context.fTheme.colors.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.fTheme.colors.mutedForeground),
            ),
            const SizedBox(height: 16),
            FButton(
              onPress: onRetry,
              child: Text('refresh'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return DateFormat('dd/MM/yyyy').format(parsed);
}

String _formatDateTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
}

String _formatRatingKey(String key) {
  return key.replaceAll('_', ' ').capitalizeFirst ?? key;
}
