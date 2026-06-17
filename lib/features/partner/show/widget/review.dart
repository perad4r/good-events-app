import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/partner/show_review_model.dart';

import '../controller.dart';

class ReviewBottomSheet extends StatefulWidget {
  const ReviewBottomSheet({
    super.key,
    required this.billId,
    required this.code,
    required this.clientName,
    required this.category,
    required this.event,
    required this.date,
    required this.price,
    required this.accentColor,
    required this.softColor,
    required this.textColor,
  });

  final int billId;
  final String code;
  final String clientName;
  final String category;
  final String event;
  final String date;
  final int price;
  final Color accentColor;
  final Color softColor;
  final Color textColor;

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  late Future<ShowReview?> _reviewFuture;

  @override
  void initState() {
    super.initState();
    _reviewFuture = _loadReview();
  }

  Future<ShowReview?> _loadReview() {
    return Get.find<ShowController>().getBillReview(widget.billId);
  }

  void _retry() {
    setState(() {
      _reviewFuture = _loadReview();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildBillSummary(context),
            const SizedBox(height: 14),
            FutureBuilder<ShowReview?>(
              future: _reviewFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState(context);
                }
                if (snapshot.hasError) {
                  return _buildErrorState(context);
                }
                final review = snapshot.data;
                if (review == null) {
                  return _buildEmptyState(context);
                }
                return _buildReviewContent(context, review);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: widget.softColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(FIcons.star, color: widget.textColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'customer_reviews'.tr,
                style: context.typography.lg.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.fTheme.colors.foreground,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.code,
                style: context.typography.xs.copyWith(
                  color: context.fTheme.colors.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillSummary(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.fTheme.colors.muted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.fTheme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewInfoRow(
            icon: FIcons.userRound,
            label: 'customer'.tr,
            value: widget.clientName,
          ),
          const SizedBox(height: 9),
          _ReviewInfoRow(
            icon: FIcons.calendarDays,
            label: 'date'.tr,
            value: widget.date,
          ),
          const SizedBox(height: 9),
          _ReviewInfoRow(
            icon: FIcons.notebookText,
            label: 'event'.tr,
            value: widget.event.isNotEmpty ? widget.event : widget.category,
          ),
          const SizedBox(height: 9),
          _ReviewInfoRow(
            icon: FIcons.badgeCheck,
            label: 'price'.tr,
            value: FormatUtils.formatCurrencyToDoule(widget.price),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return _ReviewPanel(
      softColor: widget.softColor,
      accentColor: widget.accentColor,
      child: Column(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.accentColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'loading_with_dot'.tr,
            style: context.typography.xs.copyWith(
              color: context.fTheme.colors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return _ReviewPanel(
      softColor: widget.softColor,
      accentColor: widget.accentColor,
      child: Column(
        children: [
          Icon(FIcons.refreshCw, size: 22, color: widget.textColor),
          const SizedBox(height: 8),
          Text(
            'load_data_failed'.tr,
            textAlign: TextAlign.center,
            style: context.typography.sm.copyWith(
              color: context.fTheme.colors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _retry,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: widget.accentColor,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                'refresh'.tr,
                style: context.typography.xs.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return _ReviewPanel(
      softColor: widget.softColor,
      accentColor: widget.accentColor,
      child: Column(
        children: [
          _ReviewStars(rating: 0, muted: true),
          const SizedBox(height: 10),
          Text(
            'review_pending_title'.tr,
            textAlign: TextAlign.center,
            style: context.typography.sm.copyWith(
              color: context.fTheme.colors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'review_pending_desc'.tr,
            textAlign: TextAlign.center,
            style: context.typography.xs.copyWith(
              color: context.fTheme.colors.mutedForeground,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewContent(BuildContext context, ShowReview review) {
    final comment = review.comment.trim();
    return _ReviewPanel(
      softColor: widget.softColor,
      accentColor: widget.accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _ReviewStars(rating: review.rating)),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: context.typography.sm.copyWith(
                color: context.fTheme.colors.foreground,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _ReviewInfoRow(
            icon: FIcons.badgeCheck,
            label: 'recommend'.tr,
            value:
                review.recommend ? 'client_recommends'.tr : 'client_not_recommends'.tr,
          ),
          if (review.createdAt.isNotEmpty) ...[
            const SizedBox(height: 9),
            _ReviewInfoRow(
              icon: FIcons.clock,
              label: 'review_created_at'.tr,
              value: review.createdAt,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({
    required this.softColor,
    required this.accentColor,
    required this.child,
  });

  final Color softColor;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: softColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }
}

class _ReviewStars extends StatelessWidget {
  const _ReviewStars({required this.rating, this.muted = false});

  final int rating;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final safeRating = rating.clamp(0, 5).toInt();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            FIcons.star,
            size: 18,
            color: !muted && index < safeRating
                ? const Color(0xFFF59E0B)
                : context.fTheme.colors.mutedForeground.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _ReviewInfoRow extends StatelessWidget {
  const _ReviewInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: context.fTheme.colors.mutedForeground),
        const SizedBox(width: 7),
        Text(
          label,
          style: context.typography.xs.copyWith(
            color: context.fTheme.colors.mutedForeground,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: context.typography.xs.copyWith(
              color: context.fTheme.colors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
