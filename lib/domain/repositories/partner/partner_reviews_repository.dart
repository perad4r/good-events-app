import 'package:sukientotapp/data/models/partner/partner_review_model.dart';

abstract class PartnerReviewsRepository {
  Future<PartnerReviewsPageModel> getReviews({
    required int page,
    int perPage = 10,
  });
}
