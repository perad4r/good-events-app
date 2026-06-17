import 'package:image_picker/image_picker.dart';
import 'package:sukientotapp/data/models/partner/show_bill_model.dart';
import 'package:sukientotapp/data/models/partner/show_review_model.dart';
import 'package:sukientotapp/data/providers/partner/show_provider.dart';
import 'package:sukientotapp/domain/repositories/partner/show_repository.dart';

class ShowRepositoryImpl implements ShowRepository {
  final ShowProvider _provider;

  ShowRepositoryImpl(this._provider);

  @override
  Future<ShowBillsResponse> getBills({
    required String status,
    String? search,
    String dateFilter = 'all',
    String sort = 'date_asc',
    int page = 1,
    int perPage = 5,
  }) async {
    final data = await _provider.getBills(
      status: status,
      search: search,
      dateFilter: dateFilter,
      sort: sort,
      page: page,
      perPage: perPage,
    );
    return ShowBillsResponse.fromMap(data);
  }

  @override
  Future<bool> markInJob(int billId, XFile image) async {
    return _provider.markInJob(billId, image);
  }

  @override
  Future<bool> completeBill(int billId) async {
    return _provider.completeBill(billId);
  }

  @override
  Future<bool> cancelAcceptBill(int billId) async {
    return _provider.cancelAcceptBill(billId);
  }

  @override
  Future<ShowReview?> getBillReview(int billId) async {
    final data = await _provider.getBillReview(billId);
    final review = data['review'];
    if (review == null) return null;
    return ShowReview.fromMap(review as Map<String, dynamic>);
  }
}
