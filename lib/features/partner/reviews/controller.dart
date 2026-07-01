import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/partner/partner_review_model.dart';
import 'package:sukientotapp/domain/repositories/partner/partner_reviews_repository.dart';

class PartnerReviewsController extends GetxController {
  final PartnerReviewsRepository _repository;

  PartnerReviewsController(this._repository);

  static const int _perPage = 10;

  final reviews = <PartnerReviewItemModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;
  final refreshController = RefreshController(initialRefresh: false);

  int _currentPage = 1;
  int _lastPage = 1;

  bool get hasMore => _currentPage < _lastPage;

  @override
  void onInit() {
    super.onInit();
    fetchReviews();
  }

  Future<void> fetchReviews({bool refresh = false}) async {
    if (isLoading.value) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final page = refresh ? 1 : _currentPage;
      final result = await _repository.getReviews(
        page: page,
        perPage: _perPage,
      );

      _currentPage = result.meta.currentPage;
      _lastPage = result.meta.lastPage;
      reviews.assignAll(result.reviews);

      if (!hasMore) {
        refreshController.loadNoData();
      } else {
        refreshController.resetNoData();
      }
    } catch (e) {
      logger.e('[PartnerReviewsController] [fetchReviews] Error: $e');
      errorMessage.value = e.toString();
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onRefresh() async {
    await fetchReviews(refresh: true);
    refreshController.refreshCompleted();
  }

  Future<void> onLoading() async {
    if (!hasMore || isLoadingMore.value) {
      refreshController.loadNoData();
      return;
    }

    isLoadingMore.value = true;
    try {
      final result = await _repository.getReviews(
        page: _currentPage + 1,
        perPage: _perPage,
      );

      _currentPage = result.meta.currentPage;
      _lastPage = result.meta.lastPage;
      reviews.addAll(result.reviews);

      if (hasMore) {
        refreshController.loadComplete();
      } else {
        refreshController.loadNoData();
      }
    } catch (e) {
      logger.e('[PartnerReviewsController] [onLoading] Error: $e');
      AppSnackbar.showError(title: 'error'.tr, message: e.toString());
      refreshController.loadFailed();
    } finally {
      isLoadingMore.value = false;
    }
  }

  @override
  void onClose() {
    refreshController.dispose();
    super.onClose();
  }
}
