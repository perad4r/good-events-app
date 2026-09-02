import 'package:flutter_test/flutter_test.dart';
import 'package:sukientotapp/data/models/partner/show_bill_model.dart';

void main() {
  Map<String, dynamic> billJson({Object? isOverdue}) => <String, dynamic>{
    'id': 1,
    'code': 'BILL-001',
    'category': 'MC',
    'client_name': 'Client',
    'date': '2026-09-01',
    'start_time': '08:00',
    'end_time': '10:00',
    'address': 'Ho Chi Minh City',
    'final_total': 1000000,
    'updated_at': '2026-09-01T10:00:00+07:00',
    'event': 'Wedding',
    'status': 'confirmed',
    if (isOverdue != null) 'is_overdue': isOverdue,
  };

  test('parses is_overdue from partner bill response', () {
    final bill = ShowBill.fromMap(billJson(isOverdue: true));

    expect(bill.isOverdue, isTrue);
  });

  test('defaults isOverdue to false when field is absent', () {
    final bill = ShowBill.fromMap(billJson());

    expect(bill.isOverdue, isFalse);
  });

  test('preserves isOverdue during local status transition', () {
    final bill = ShowBill.fromMap(billJson(isOverdue: true));

    expect(bill.copyWith(status: 'in_job').isOverdue, isTrue);
  });
}
