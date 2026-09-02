import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/message_model.dart';
import '../controller.dart';

class PriceIncreaseRequestCard extends StatefulWidget {
  const PriceIncreaseRequestCard({
    super.key,
    required this.request,
    this.showActions = true,
  });

  final PriceIncreaseRequestModel request;
  final bool showActions;

  @override
  State<PriceIncreaseRequestCard> createState() => _PriceIncreaseRequestCardState();
}

class _PriceIncreaseRequestCardState extends State<PriceIncreaseRequestCard> {
  bool _processing = false;
  String? _localStatus;

  String get _status => _localStatus ?? widget.request.status;

  @override
  void didUpdateWidget(covariant PriceIncreaseRequestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.id != widget.request.id ||
        oldWidget.request.status != widget.request.status) {
      _localStatus = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MessageController>();
    final canRespond = widget.showActions && !controller.isPartner && _status == 'pending';
    final statusColor = switch (_status) {
      'accepted' => const Color(0xFF15803D),
      'rejected' => const Color(0xFFDC2626),
      'pending' => const Color(0xFFD97706),
      _ => const Color(0xFF64748B),
    };
    final statusLabel = switch (_status) {
      'accepted' => 'Đã đồng ý',
      'rejected' => 'Đã từ chối',
      'superseded' => 'Đã thay thế',
      'cancelled' => 'Đã hủy',
      _ => 'Chờ phản hồi',
    };

    return Container(
      width: 285,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.trending_up_rounded, color: Color(0xFFEA580C), size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Yêu cầu tăng giá', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: .1), borderRadius: BorderRadius.circular(99)),
              child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 14),
          _PriceRow(label: 'Giá hiện tại', value: _money(widget.request.originalTotal), muted: true),
          const SizedBox(height: 6),
          _PriceRow(label: 'Giá đề nghị', value: _money(widget.request.requestedTotal)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
          const Text('Lý do', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          const SizedBox(height: 4),
          Text(widget.request.reason, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, height: 1.4)),
          if (canRespond) ...[
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _processing ? null : () => _respond(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      backgroundColor: const Color(0xFFFEF2F2),
                      disabledForegroundColor: const Color(0xFFDC2626).withValues(alpha: 0.45),
                      disabledBackgroundColor: const Color(0xFFFEF2F2).withValues(alpha: 0.6),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 17),
                    label: const Text(
                      'Từ chối',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _processing ? null : () => _respond(true),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.primary,
                      disabledForegroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.55),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: _processing
                        ? const SizedBox.square(
                            dimension: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 17),
                    label: Text(
                      _processing ? 'Đang xử lý' : 'Đồng ý',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Future<void> _respond(bool accept) async {
    setState(() => _processing = true);
    final success = await Get.find<MessageController>().respondToPriceIncreaseRequest(
      request: widget.request,
      accept: accept,
    );
    if (mounted) setState(() {
      _processing = false;
      if (success) {
        _localStatus = accept ? 'accepted' : 'rejected';
      }
    });
  }

  String _money(int value) => '${NumberFormat.decimalPattern('vi_VN').format(value)} ₫';
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value, this.muted = false});
  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
    Text(value, style: TextStyle(color: muted ? const Color(0xFF64748B) : AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
  ]);
}
