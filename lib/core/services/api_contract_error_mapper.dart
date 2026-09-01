import 'package:sukientotapp/core/utils/app_exceptions.dart';

class ApiContractErrorMapper {
  const ApiContractErrorMapper._();

  static Exception? fromResponseData(Object? data) {
    if (data is! Map) return null;

    final code = data['code']?.toString();
    switch (code) {
      case 'PARTNER_WORKFLOW_LOCKED':
        return const PartnerWorkflowLockedException();
      case 'ACCOUNT_SUSPENDED':
        final rawReason = data['ban_reason']?.toString().trim();
        final rawSuspendedAt = data['suspended_at']?.toString();
        return AccountSuspendedException(
          message: data['message']?.toString() ?? 'Account suspended.',
          banReason: rawReason == null || rawReason.isEmpty
              ? 'Tài khoản của bạn đã bị tạm khóa.'
              : rawReason,
          suspendedAt: rawSuspendedAt == null
              ? null
              : DateTime.tryParse(rawSuspendedAt),
        );
      default:
        return null;
    }
  }
}
