import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/domain/repositories/common/report_repository.dart';

Future<void> showReportBottomSheet({
  int? reportedUserId,
  int? reportedBillId,
  String? billCode,
}) {
  return Get.bottomSheet<void>(
    _ReportBottomSheet(
      reportedUserId: reportedUserId,
      reportedBillId: reportedBillId,
      billCode: billCode,
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _ReportBottomSheet extends StatefulWidget {
  final int? reportedUserId;
  final int? reportedBillId;
  final String? billCode;

  const _ReportBottomSheet({
    required this.reportedUserId,
    required this.reportedBillId,
    required this.billCode,
  });

  @override
  State<_ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<_ReportBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final ReportRepository _reportRepository;

  bool _isSubmitting = false;
  Map<String, List<String>> _errors = <String, List<String>>{};

  bool get _isBillReport => widget.reportedBillId != null;

  String get _sheetTitle {
    if (!_isBillReport) {
      return 'report_user_title'.tr;
    }

    final billCode = widget.billCode?.trim();
    if (billCode == null || billCode.isEmpty) {
      return 'report_bill_title'.tr;
    }

    return '${'report_bill_title'.tr} - $billCode';
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _reportRepository = Get.find<ReportRepository>();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errors = <String, List<String>>{};
    });

    try {
      final result = _isBillReport
          ? await _reportRepository.reportBill(
              reportedBillId: widget.reportedBillId!,
              title: _titleController.text,
              description: _descriptionController.text,
            )
          : await _reportRepository.reportUser(
              reportedUserId: widget.reportedUserId!,
              title: _titleController.text,
              description: _descriptionController.text,
            );

      if (result['success'] == true) {
        if (Get.isBottomSheetOpen == true) {
          Get.back<void>();
        }
        Get.snackbar('success'.tr, 'report_success_message'.tr);
        return;
      }

      if (mounted) {
        setState(() {
          _errors = _parseErrors(result['errors']);
        });
      }

      Get.snackbar('error'.tr, result['message'] ?? 'report_failed'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Map<String, List<String>> _parseErrors(dynamic rawErrors) {
    if (rawErrors is! Map) {
      return <String, List<String>>{};
    }

    final parsed = <String, List<String>>{};
    for (final entry in rawErrors.entries) {
      final value = entry.value;
      if (value is List) {
        parsed[entry.key.toString()] = value
            .map((item) => item.toString())
            .toList();
      }
    }
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    final titleError = _errors['title']?.join('\n');
    final descriptionError = _errors['description']?.join('\n');
    final targetField = _isBillReport ? 'reported_bill_id' : 'reported_user_id';
    final targetError = _errors[targetField]?.join('\n');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _sheetTitle,
                    style: context.typography.lg.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isSubmitting ? null : () => Get.back<void>(),
                  icon: const Icon(Icons.close),
                  tooltip: 'close'.tr,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'report_dialog_description'.tr,
              style: context.typography.sm.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              'report_title_label'.tr,
              style: context.typography.sm.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'report_title_hint'.tr,
                errorText: titleError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'report_desc_label'.tr,
              style: context.typography.sm.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'report_desc_hint'.tr,
                errorText: descriptionError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            if (targetError != null) ...[
              const SizedBox(height: 12),
              Text(
                targetError,
                style: context.typography.xs.copyWith(color: Colors.red),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'submit_report'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
