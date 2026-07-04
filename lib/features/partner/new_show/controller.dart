import 'dart:convert';

import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/partner/partner_bill_model.dart';
import 'package:sukientotapp/domain/repositories/partner/new_show_repository.dart';
import 'package:sukientotapp/features/partner/home/controller.dart';
import 'package:sukientotapp/features/partner/show/controller.dart';
import 'package:sukientotapp/features/common/message/controller.dart';

class NewShowController extends GetxController {
  final NewShowRepository _repository;
  NewShowController(this._repository);

  final isLoading = false.obs;
  final hasMorePages = true.obs;
  final ScrollController scrollController = ScrollController();

  final bills = <PartnerBill>[].obs;
  final lastUpdated = ''.obs;

  // ─── Filter State ────────────────────────────────────────────────────────────
  final filterSearch = ''.obs;
  final filterDate = 'all'.obs;
  final filterSort = 'date_asc'.obs;
  final filteredBills = <PartnerBill>[].obs;

  bool get isFilterActive =>
      filterSearch.value.isNotEmpty ||
      filterDate.value != 'all' ||
      filterSort.value != 'date_asc';

  int _currentPage = 1;
  final _subscribedChannels = <String>[];
  DateTime? _lastScrollFetchTime;
  DateTime? _lastRefreshTime;

  static const _pusherEventName = 'NewPartnerBillCreated';
  static const _scrollFetchCooldown = Duration(seconds: 3);
  static const _refreshCooldown = Duration(seconds: 5);

  @override
  void onInit() {
    super.onInit();
    fetchRealtimeBills();
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !isLoading.value &&
        hasMorePages.value) {
      fetchRealtimeBills();
    }
  }

  // ─── Filter Logic ────────────────────────────────────────────────────────────

  void applyFilter({
    required String search,
    required String dateFilter,
    required String sort,
  }) {
    filterSearch.value = search;
    filterDate.value = dateFilter;
    filterSort.value = sort;
    _applyLocalFilter();
  }

  void clearFilter() {
    filterSearch.value = '';
    filterDate.value = 'all';
    filterSort.value = 'date_asc';
    filteredBills.clear();
  }

  void _applyLocalFilter() {
    var result = List<PartnerBill>.from(bills);

    final q = filterSearch.value.toLowerCase().trim();
    if (q.isNotEmpty) {
      result = result
          .where(
            (b) =>
                b.code.toLowerCase().contains(q) ||
                b.clientName.toLowerCase().contains(q) ||
                b.eventName.toLowerCase().contains(q) ||
                b.categoryName.toLowerCase().contains(q) ||
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
        result.sort((a, b) => (a.finalTotal ?? 0).compareTo(b.finalTotal ?? 0));
        break;
      case 'price_desc':
        result.sort((a, b) => (b.finalTotal ?? 0).compareTo(a.finalTotal ?? 0));
        break;
      default: // date_asc
        result.sort((a, b) => a.date.compareTo(b.date));
        break;
    }

    filteredBills.value = result;
  }

  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> fetchRealtimeBills({bool isInitialFetch = true}) async {
    if (isLoading.value) return;

    if (isInitialFetch) {
      if (!hasMorePages.value) return;
      final now = DateTime.now();
      if (_lastScrollFetchTime != null &&
          now.difference(_lastScrollFetchTime!) < _scrollFetchCooldown) {
        return;
      }
      _lastScrollFetchTime = now;
    }

    isLoading.value = true;
    final pageToFetch = _currentPage;
    try {
      final response = await _repository.getRealtimeBills(page: pageToFetch);

      if (pageToFetch == 1) {
        if (!isInitialFetch) {
          final existingIds = bills.map((b) => b.id).toSet();
          final newCount = response.partnerBills
              .where((b) => !existingIds.contains(b.id))
              .length;
          if (newCount > 0 && Get.isRegistered<PartnerHomeController>()) {
            Get.find<PartnerHomeController>().updateShowDataOnNewBill(
              count: newCount,
            );
          }
        }
        bills.assignAll(response.partnerBills);
        await _subscribeToBroadcastChannels(response.broadcastChannels);
      } else {
        bills.addAll(response.partnerBills);
      }

      lastUpdated.value = response.lastUpdated;

      if (response.partnerBills.length >= response.meta.perPage) {
        _currentPage = response.meta.currentPage + 1;
        hasMorePages.value = true;
      } else {
        hasMorePages.value = false;
      }

      logger.i(
        '[NewShow] [Fetch] Page $pageToFetch - ${bills.length} loaded bills',
      );
    } catch (e) {
      logger.e('[NewShow] [Fetch] Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshBills() async {
    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _refreshCooldown) {
      AppSnackbar.showInfo(
        message: 'please_wait_before_refreshing'.tr,
        title: 'cooldown_active'.trParams({
          'seconds': _refreshCooldown.inSeconds.toString(),
        }),
      );

      logger.w('[NewShow] [Refresh] Cooldown active, skipping');
      return;
    }
    _lastRefreshTime = now;
    _currentPage = 1;
    hasMorePages.value = true;
    await fetchRealtimeBills(isInitialFetch: false);
  }

  Future<void> reloadAfterServiceAreasChanged() async {
    if (isLoading.value) {
      logger.w(
        '[NewShow] [ServiceAreasReload] Waiting for current loading to finish',
      );
      await _waitForCurrentLoading();
      if (isLoading.value) {
        logger.w('[NewShow] [ServiceAreasReload] Skipped after wait timeout');
        return;
      }
    }

    logger.i('[NewShow] [ServiceAreasReload] Reloading bills and channels');

    await _unsubscribeAll();
    _currentPage = 1;
    _lastScrollFetchTime = null;
    _lastRefreshTime = null;
    hasMorePages.value = true;
    bills.clear();
    filterSearch.value = '';
    filterDate.value = 'all';
    filterSort.value = 'date_asc';
    filteredBills.clear();
    lastUpdated.value = '';

    await fetchRealtimeBills();
  }

  Future<void> _waitForCurrentLoading() async {
    for (int i = 0; i < 20; i++) {
      if (!isLoading.value) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  final isAccepting = false.obs;

  Future<bool> acceptBill({required int billId, required double price}) async {
    isAccepting.value = true;
    try {
      final errorCode = await _repository.acceptBill(billId: billId, price: price);
      if (errorCode != null) {
        final messageKey = _acceptErrorKey(errorCode);
        AppSnackbar.showError(
          message: messageKey.tr,
          title: 'failed'.tr,
        );
        return false;
      }

      bills.removeWhere((b) => b.id == billId);
      if (Get.isRegistered<PartnerHomeController>()) {
        Get.find<PartnerHomeController>().updateShowDataOnAccept();
      }
      if (Get.isRegistered<ShowController>()) {
        Get.find<ShowController>().refreshNewBills();
      }
      if (Get.isRegistered<MessageController>()) {
        Get.find<MessageController>().refreshThreads();
      }

      logger.i('[NewShow] [Accept] Bill $billId accepted at price $price');
      return true;
    } catch (e) {
      logger.e('[NewShow] [Accept] Error: $e');

      AppSnackbar.showError(
        message: 'failed_to_accept_show'.tr,
        title: 'failed'.tr,
      );
      return false;
    } finally {
      isAccepting.value = false;
    }
  }

  String _acceptErrorKey(String code) {
    switch (code) {
      case 'NOT_ALLOWED_TO_ACCEPT_ORDERS':
        return 'accept_error_not_allowed';
      case 'INSUFFICIENT_BALANCE':
        return 'accept_error_insufficient_balance';
      case 'ORDER_NOT_PENDING':
        return 'accept_error_order_not_pending';
      default:
        return 'failed_to_accept_show';
    }
  }

  Future<void> _subscribeToBroadcastChannels(List<String> channels) async {
    await _unsubscribeAll();

    for (final channelName in channels) {
      await PusherService.subscribe(
        channelName: channelName,
        eventName: _pusherEventName,
        onEvent: _onPusherEvent,
      );
      _subscribedChannels.add(channelName);
    }
  }

  void _onPusherEvent(PusherEvent event) {
    if (event.eventName != _pusherEventName) return;
    if (event.data == null) return;

    try {
      final data = jsonDecode(event.data!) as Map<String, dynamic>;

      if (data.containsKey('id') && data.containsKey('code')) {
        final newBill = PartnerBill.fromMap(data);
        bills.insert(0, newBill);
        lastUpdated.value = DateFormat('HH:mm:ss').format(DateTime.now());
        if (Get.isRegistered<PartnerHomeController>()) {
          Get.find<PartnerHomeController>().updateShowDataOnNewBill();
        }
        logger.i('[NewShow] [Pusher] New bill received: ${newBill.code}');
      } else {
        final response = RealtimeBillsResponse.fromMap(data);
        bills.insertAll(0, response.partnerBills);
        lastUpdated.value = response.lastUpdated;
        if (Get.isRegistered<PartnerHomeController>()) {
          Get.find<PartnerHomeController>().updateShowDataOnNewBill(
            count: response.partnerBills.length,
          );
        }
        logger.i(
          '[NewShow] [Pusher] ${response.partnerBills.length} new bill(s) received',
        );
      }
    } catch (e) {
      logger.e('[NewShow] [Pusher] Error parsing event: $e');
    }
  }

  Future<void> _unsubscribeAll() async {
    for (final channel in _subscribedChannels) {
      await PusherService.unsubscribe(channel);
    }
    _subscribedChannels.clear();
  }

  @override
  void onClose() {
    _unsubscribeAll();
    scrollController.dispose();
    super.onClose();
  }
}
