import 'package:image_picker/image_picker.dart';
import 'package:sukientotapp/data/models/partner/show_bill_model.dart';
import 'package:sukientotapp/data/models/partner/show_review_model.dart';

abstract class ShowRepository {
  Future<ShowBillsResponse> getBills({
    required String status,
    String? search,
    String dateFilter = 'all',
    String sort = 'date_asc',
    int page = 1,
    int perPage = 5,
  });

  Future<bool> markInJob(int billId, XFile image);

  Future<bool> completeBill(int billId);

  Future<bool> cancelAcceptBill(int billId);

  Future<ShowReview?> getBillReview(int billId);
}
