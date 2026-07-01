import 'package:sukientotapp/core/utils/import/global.dart';
import '../controller/controller.dart';

class UserReviewSection extends GetView<ClientOrderDetailController> {
  const UserReviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final review = controller.review;
      if (review == null) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50], // amber-50
          border: Border.all(color: Colors.orange[200]!), // amber-200
          borderRadius: BorderRadius.circular(12), // rounded-xl
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), // shadow-sm
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.star_rounded, color: Colors.orange[500], size: 24),
            const SizedBox(width: 12), // gap-3
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đánh giá của bạn (${review.rating} sao)', // text-xs text-amber-700
                    style: context.typography.xs.copyWith(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      review.comment!.trim(), // text-sm md:text-md text-amber-900
                      style: context.typography.sm.copyWith(
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
