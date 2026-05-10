part of 'controller.dart';

extension ClientOrderDetailReport on ClientOrderDetailController {
  Future<void> submitReport() async {
    isSubmittingReport.value = true;
    reportErrors.clear();

    try {
      final result = await _repository.reportBill(
        reportedBillId: orderId,
        title: reportTitleController.text,
        description: reportDescriptionController.text,
      );

      if (result['success'] == true) {
        Get.back(); // close bottom sheet
        Get.snackbar(
          'success'.tr,
          'report_success_message'.tr,
        );
        reportTitleController.clear();
        reportDescriptionController.clear();
      } else {
        bool hasFieldErrors = false;
        if (result['errors'] != null && result['errors'] is Map) {
          final Map<dynamic, dynamic> errors = result['errors'];
          final Map<String, List<String>> parsedErrors = {};

          for (var entry in errors.entries) {
            if (entry.value is List) {
              parsedErrors[entry.key.toString()] = (entry.value as List)
                  .map((e) => e.toString())
                  .toList();
            }
          }
          reportErrors.value = parsedErrors;
          hasFieldErrors = parsedErrors.isNotEmpty;
        }

        if (!hasFieldErrors && Get.isBottomSheetOpen == true) {
          Get.back();
        }

        Get.snackbar(
          'error'.tr,
          result['message'] ?? 'report_failed'.tr,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
      );
    } finally {
      isSubmittingReport.value = false;
    }
  }
}
