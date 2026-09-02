import 'package:flutter_test/flutter_test.dart';
import 'package:sukientotapp/core/services/api_contract_error_mapper.dart';
import 'package:sukientotapp/core/utils/app_exceptions.dart';

void main() {
  test('maps partner workflow lock to its domain exception', () {
    final error = ApiContractErrorMapper.fromResponseData(<String, dynamic>{
      'code': 'PARTNER_WORKFLOW_LOCKED',
    });

    expect(error, isA<PartnerWorkflowLockedException>());
  });

  test('maps suspended account reason and optional timestamp', () {
    final error = ApiContractErrorMapper.fromResponseData(<String, dynamic>{
      'code': 'ACCOUNT_SUSPENDED',
      'message': 'Account suspended.',
      'ban_reason': 'Tạm khóa do vi phạm quy trình',
      'suspended_at': '2026-09-01T01:30:00+07:00',
    });

    expect(error, isA<AccountSuspendedException>());
    final suspended = error! as AccountSuspendedException;
    expect(suspended.banReason, 'Tạm khóa do vi phạm quy trình');
    expect(suspended.suspendedAt, isNotNull);
  });

  test('does not classify generic auth errors as suspension', () {
    final error = ApiContractErrorMapper.fromResponseData(<String, dynamic>{
      'code': 'INVALID_TOKEN',
    });

    expect(error, isNull);
  });
}
