import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/partner/show_bill_model.dart';
import 'package:sukientotapp/data/models/partner/show_review_model.dart';
import 'package:sukientotapp/domain/repositories/partner/show_repository.dart';
import 'package:sukientotapp/features/partner/home/controller.dart';
import 'package:sukientotapp/features/partner/new_show/controller.dart';

class ShowController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final ShowRepository _repository;
  ShowController(this._repository);

  final isLoading = false.obs;
  final isSearching = false.obs;
  final selectedImage = Rxn<XFile>();
  final selectedCompletionImage = Rxn<XFile>();

  final searchController = TextEditingController();

  // ─── Filter State ────────────────────────────────────────────────────────────
  final filterSearch = ''.obs;
  final filterDate = 'all'.obs;
  final filterSort = 'date_asc'.obs;

  bool get isFilterActive =>
      filterSearch.value.isNotEmpty ||
      filterDate.value != 'all' ||
      filterSort.value != 'date_asc';

  final filteredNewBills = <ShowBill>[].obs;
  final filteredUpcomingBills = <ShowBill>[].obs;
  final filteredHistoryBills = <ShowBill>[].obs;

  late TabController tabController;
  final _tabInitialized = [false, false, false];

  // --- New tab (status: pending) ---
  final ScrollController scrollController = ScrollController();
  final newBills = <ShowBill>[].obs;
  final isLoadMore = false.obs;
  int _newPage = 1;
  int _newLastPage = 1;

  // --- Upcoming tab (status: confirmed) ---
  final ScrollController upcomingScrollController = ScrollController();
  final upcomingBills = <ShowBill>[].obs;
  final isUpcomingLoading = false.obs;
  final isUpcomingLoadMore = false.obs;
  int _upcomingPage = 1;
  int _upcomingLastPage = 1;

  // --- History tab (status: history) ---
  final ScrollController historyScrollController = ScrollController();
  final historyBills = <ShowBill>[].obs;
  final isHistoryLoading = false.obs;
  final isHistoryLoadMore = false.obs;
  int _historyPage = 1;
  int _historyLastPage = 1;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(_onTabChanged);
    _fetchNewBills(reset: true);
    _tabInitialized[0] = true;

    scrollController.addListener(_onScroll);
    upcomingScrollController.addListener(_onUpcomingScroll);
    historyScrollController.addListener(_onHistoryScroll);
  }

  void _onTabChanged() {
    if (tabController.indexIsChanging) return;
    final index = tabController.index;
    if (_tabInitialized[index]) return;
    _tabInitialized[index] = true;
    if (index == 1) {
      _fetchUpcomingBills(reset: true);
    } else if (index == 2) {
      _fetchHistoryBills(reset: true);
    }
  }

  void switchTab(int index) {
    tabController.animateTo(index);
  }

  Future<void> refreshData() async {
    final index = tabController.index;
    _tabInitialized[index] = true;
    if (isFilterActive) {
      await _applyFilterForTab(index);
      return;
    }
    if (index == 0) {
      await _fetchNewBills(reset: true);
    } else if (index == 1) {
      await _fetchUpcomingBills(reset: true);
    } else if (index == 2) {
      await _fetchHistoryBills(reset: true);
    }
  }

  // ─── Filter Logic ────────────────────────────────────────────────────────────

  Future<void> applyFilter({
    required String search,
    required String dateFilter,
    required String sort,
  }) async {
    filterSearch.value = search;
    filterDate.value = dateFilter;
    filterSort.value = sort;
    await _applyFilterForTab(tabController.index);
  }

  Future<void> clearFilter() async {
    filterSearch.value = '';
    filterDate.value = 'all';
    filterSort.value = 'date_asc';
    filteredNewBills.clear();
    filteredUpcomingBills.clear();
    filteredHistoryBills.clear();
  }

  List<ShowBill> _filterLocally(List<ShowBill> source) {
    var result = List<ShowBill>.from(source);

    final q = filterSearch.value.toLowerCase().trim();
    if (q.isNotEmpty) {
      result = result
          .where(
            (b) =>
                b.code.toLowerCase().contains(q) ||
                b.clientName.toLowerCase().contains(q) ||
                b.event.toLowerCase().contains(q) ||
                b.category.toLowerCase().contains(q) ||
                b.address.toLowerCase().contains(q),
          )
          .toList();
    }

    if (filterDate.value != 'all') {
      final now = DateTime.now();
      result = result.where((b) {
        final date = DateTime.tryParse(b.date);
        if (date == null) return false;
        switch (filterDate.value) {
          case 'today':
            return date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
          case 'this_week':
            final start = now.subtract(Duration(days: now.weekday - 1));
            final end = start.add(const Duration(days: 6));
            return !date.isBefore(
                  DateTime(start.year, start.month, start.day),
                ) &&
                !date.isAfter(DateTime(end.year, end.month, end.day, 23, 59));
          case 'this_month':
            return date.year == now.year && date.month == now.month;
          default:
            return true;
        }
      }).toList();
    }

    switch (filterSort.value) {
      case 'date_desc':
        result.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'price_asc':
        result.sort((a, b) => a.finalTotal.compareTo(b.finalTotal));
        break;
      case 'price_desc':
        result.sort((a, b) => b.finalTotal.compareTo(a.finalTotal));
        break;
      default: // date_asc
        result.sort((a, b) => a.date.compareTo(b.date));
        break;
    }

    return result;
  }

  Future<void> _applyFilterForTab(int index) async {
    final String status;
    final List<ShowBill> source;
    if (index == 0) {
      status = 'pending';
      source = newBills;
    } else if (index == 1) {
      status = 'confirmed';
      source = upcomingBills;
    } else {
      status = 'history';
      source = historyBills;
    }

    final localResult = _filterLocally(source);
    if (localResult.isNotEmpty) {
      if (index == 0) {
        filteredNewBills.value = localResult;
      } else if (index == 1) {
        filteredUpcomingBills.value = localResult;
      } else {
        filteredHistoryBills.value = localResult;
      }
      return;
    }

    // No local match → call API with filter params
    if (index == 0) {
      isLoading.value = true;
    } else if (index == 1) {
      isUpcomingLoading.value = true;
    } else {
      isHistoryLoading.value = true;
    }

    try {
      final response = await _repository.getBills(
        status: status,
        search: filterSearch.value.isEmpty ? null : filterSearch.value,
        dateFilter: filterDate.value,
        sort: filterSort.value,
        page: 1,
      );
      if (index == 0) {
        filteredNewBills.value = response.bills;
      } else if (index == 1) {
        filteredUpcomingBills.value = response.bills;
      } else {
        filteredHistoryBills.value = response.bills;
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'load_data_failed'.tr);
      logger.e('[Show] [Filter] API filter error: $e');
    } finally {
      if (index == 0) {
        isLoading.value = false;
      } else if (index == 1) {
        isUpcomingLoading.value = false;
      } else {
        isHistoryLoading.value = false;
      }
    }
  }

  // ─── New Tab ────────────────────────────────────────────────────────────────

  Future<void> refreshNewBills() => _fetchNewBills(reset: true);
  Future<void> refreshUpcomingBills() => _fetchUpcomingBills(reset: true);

  Future<void> _fetchNewBills({bool reset = false}) async {
    final oldCount = reset ? newBills.length : null;

    if (reset) {
      _newPage = 1;
      _newLastPage = 1;
      newBills.clear();
      isLoading.value = true;
    }

    try {
      final response = await _repository.getBills(
        status: 'pending',
        page: _newPage,
      );
      _newLastPage = response.meta.lastPage;
      newBills.addAll(response.bills);

      if (oldCount != null && Get.isRegistered<PartnerHomeController>()) {
        final diff = oldCount - newBills.length;

        if (diff > 0) {
          Get.find<PartnerHomeController>().updateShowDataOnConfirmedByClient(
            count: diff,
          );
          logger.i(
            '[Show] [NewBills] $diff bill(s) moved to waiting confirmation',
          );
        }
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'load_data_failed'.tr);
      logger.e('Failed to load new bills: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !isLoadMore.value &&
        _newPage < _newLastPage) {
      loadMore();
    }
  }

  Future<void> loadMore() async {
    isLoadMore.value = true;
    _newPage++;
    try {
      final response = await _repository.getBills(
        status: 'pending',
        page: _newPage,
      );
      _newLastPage = response.meta.lastPage;
      newBills.addAll(response.bills);
    } catch (e) {
      _newPage--;
    } finally {
      isLoadMore.value = false;
    }
  }

  // ─── Upcoming Tab ────────────────────────────────────────────────────────────

  Future<void> _fetchUpcomingBills({bool reset = false}) async {
    if (reset) {
      _upcomingPage = 1;
      _upcomingLastPage = 1;
      upcomingBills.clear();
      isUpcomingLoading.value = true;
    }
    try {
      final response = await _repository.getBills(
        status: 'confirmed',
        page: _upcomingPage,
      );
      _upcomingLastPage = response.meta.lastPage;
      upcomingBills.addAll(response.bills);
    } catch (e) {
      Get.snackbar('error'.tr, 'load_data_failed'.tr);
      logger.e('Failed to load upcoming bills: $e');
    } finally {
      isUpcomingLoading.value = false;
    }
  }

  void _onUpcomingScroll() {
    if (upcomingScrollController.position.pixels >=
            upcomingScrollController.position.maxScrollExtent - 200 &&
        !isUpcomingLoadMore.value &&
        _upcomingPage < _upcomingLastPage) {
      loadMoreUpcoming();
    }
  }

  Future<void> loadMoreUpcoming() async {
    isUpcomingLoadMore.value = true;
    _upcomingPage++;
    try {
      final response = await _repository.getBills(
        status: 'confirmed',
        page: _upcomingPage,
      );
      _upcomingLastPage = response.meta.lastPage;
      upcomingBills.addAll(response.bills);
    } catch (e) {
      _upcomingPage--;
    } finally {
      isUpcomingLoadMore.value = false;
    }
  }

  // ─── History Tab ─────────────────────────────────────────────────────────────

  Future<void> _fetchHistoryBills({bool reset = false}) async {
    if (reset) {
      _historyPage = 1;
      _historyLastPage = 1;
      historyBills.clear();
      isHistoryLoading.value = true;
    }
    try {
      final response = await _repository.getBills(
        status: 'history',
        page: _historyPage,
      );
      _historyLastPage = response.meta.lastPage;
      historyBills.addAll(response.bills);
    } catch (e) {
      Get.snackbar('error'.tr, 'load_data_failed'.tr);
      logger.e('Failed to load history bills: $e');
    } finally {
      isHistoryLoading.value = false;
    }
  }

  void _onHistoryScroll() {
    if (historyScrollController.position.pixels >=
            historyScrollController.position.maxScrollExtent - 200 &&
        !isHistoryLoadMore.value &&
        _historyPage < _historyLastPage) {
      loadMoreHistory();
    }
  }

  Future<void> loadMoreHistory() async {
    isHistoryLoadMore.value = true;
    _historyPage++;
    try {
      final response = await _repository.getBills(
        status: 'history',
        page: _historyPage,
      );
      _historyLastPage = response.meta.lastPage;
      historyBills.addAll(response.bills);
    } catch (e) {
      _historyPage--;
    } finally {
      isHistoryLoadMore.value = false;
    }
  }

  Future<ShowReview?> getBillReview(int billId) {
    return _repository.getBillReview(billId);
  }

  // ─── Complete Bill ────────────────────────────────────────────────────────────

  Future<bool> validateShowPhoto(XFile image) async {
    const maxSizeBytes = 20 * 1024 * 1024;
    const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

    final ext = image.name.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      AppSnackbar.showError(
        title: 'error'.tr,
        message: 'image_format_not_supported'.tr,
      );
      return false;
    }

    final size = await image.length();
    if (size > maxSizeBytes) {
      AppSnackbar.showError(
        title: 'error'.tr,
        message: 'show_photo_image_too_large'.tr,
      );
      return false;
    }

    return true;
  }

  Future<void> completeBill(int billId) async {
    final image = selectedCompletionImage.value;
    if (image == null) {
      AppSnackbar.showError(message: 'completion_photo_required'.tr);
      return;
    }

    isLoading.value = true;
    try {
      final success = await _repository.completeBill(billId, image);
      Get.back();

      if (!success) {
        refreshData();

        AppSnackbar.showError(message: 'load_data_failed'.tr);
        return;
      }

      selectedCompletionImage.value = null;
      final index = upcomingBills.indexWhere((b) => b.id == billId);
      if (index != -1) {
        final completedBill = upcomingBills[index].copyWith(
          status: 'completed',
        );
        upcomingBills.removeAt(index);
        historyBills.insert(0, completedBill);
      } else {
        await _fetchHistoryBills(reset: true);
      }
      AppSnackbar.showSuccess(message: 'complete_bill_success'.tr);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = e.response?.data?['message'] as String?;
      if (statusCode == 403) {
        logger.e('[Show] [CompleteBill] 403 Forbidden: $e');
        await _fetchUpcomingBills(reset: true);
      } else if (statusCode == 422 &&
          message != null &&
          message.toLowerCase().contains('balance')) {
        AppSnackbar.showError(message: 'insufficient_balance'.tr);
        logger.e('[Show] [CompleteBill] 422 Insufficient balance: $e');
      } else {
        AppSnackbar.showError(message: message ?? 'load_data_failed'.tr);
        logger.e('[Show] [CompleteBill] Error $statusCode: $e');
      }
    } catch (e) {
      AppSnackbar.showError(message: 'load_data_failed'.tr);
      logger.e('[Show] [CompleteBill] Unexpected error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Mark In Job ─────────────────────────────────────────────────────────────

  Future<void> markInJob(int billId) async {
    final image = selectedImage.value;
    if (image == null) {
      AppSnackbar.showError(message: 'arrival_photo_required'.tr);
      return;
    }

    isLoading.value = true;
    try {
      final success = await _repository.markInJob(billId, image);
      Get.back();

      if (!success) {
        refreshData();

        AppSnackbar.showError(message: 'load_data_failed'.tr);
        return;
      }

      selectedImage.value = null;
      final index = upcomingBills.indexWhere((b) => b.id == billId);
      if (index != -1) {
        upcomingBills[index] = upcomingBills[index].copyWith(status: 'in_job');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = e.response?.data?['message'] as String?;
      if (statusCode == 403) {
        AppSnackbar.showError(message: message ?? 'forbidden'.tr);
      } else if (statusCode == 422) {
        AppSnackbar.showError(message: message ?? 'invalid_request'.tr);
      } else {
        AppSnackbar.showError(message: 'load_data_failed'.tr);
      }
      logger.e('[Show] [MarkInJob] Error $statusCode: $e');
      await _fetchUpcomingBills(reset: true);
    } catch (e) {
      AppSnackbar.showError(message: 'load_data_failed'.tr);
      logger.e('[Show] [MarkInJob] Unexpected error: $e');
      await _fetchUpcomingBills(reset: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelAcceptBill(int billId) async {
    isLoading.value = true;
    try {
      final success = await _repository.cancelAcceptBill(billId);
      Get.back();

      if (!success) {
        refreshData();

        AppSnackbar.showError(message: 'cancel_book_show_failed'.tr);
        return;
      }

      newBills.removeWhere((b) => b.id == billId);
      filteredNewBills.removeWhere((b) => b.id == billId);

      if (Get.isRegistered<PartnerHomeController>()) {
        Get.find<PartnerHomeController>().updateShowDataOnCancelAccept();
      }
      if (Get.isRegistered<NewShowController>()) {
        Get.find<NewShowController>().refreshBills();
      }

      AppSnackbar.showSuccess(message: 'cancel_book_show_success'.tr);
    }
    // on DioException catch (e) {
    //   final statusCode = e.response?.statusCode;
    //   final message = e.response?.data?['message'] as String?;
    //   AppSnackbar.showError(message: message ?? 'cancel_book_show_failed'.tr);
    //   logger.e('[Show] [CancelBill] Error $statusCode: $e');
    //   await refreshData();
    // }
    catch (e) {
      AppSnackbar.showError(message: 'cancel_book_show_failed'.tr);
      logger.e('[Show] [CancelBill] Unexpected error: $e');
      await refreshData();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    upcomingScrollController.dispose();
    historyScrollController.dispose();
    tabController.dispose();
    searchController.dispose();
    super.onClose();
  }
}
