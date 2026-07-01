import 'package:sukientotapp/data/models/partner/partner_review_model.dart';
import 'package:sukientotapp/data/providers/partner/partner_reviews_provider.dart';
import 'package:sukientotapp/domain/repositories/partner/partner_reviews_repository.dart';

class PartnerReviewsRepositoryImpl implements PartnerReviewsRepository {
  final PartnerReviewsProvider _provider;

  PartnerReviewsRepositoryImpl(this._provider);

  @override
  Future<PartnerReviewsPageModel> getReviews({
    required int page,
    int perPage = 10,
  }) async {
    final data = await _provider.getReviews(page: page, perPage: perPage);
    return PartnerReviewsPageModel.fromMap(data);
  }
}
