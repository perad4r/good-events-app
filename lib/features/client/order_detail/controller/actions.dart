part of 'controller.dart';

extension ClientOrderDetailActions on ClientOrderDetailController {
  Future<void> fetchOrderDetails({bool showLoading = true}) async {
    if (showLoading) isLoadingDetails.value = true;
    try {
      if (isHistory.value) {
        // For history orders: fetch the single history order + its details in parallel
        final results = await Future.wait([
          _repository.getOrderDetails(orderId),
          _repository.getHistoryOrder(orderId),
        ]);

        final details = results[0] as OrderDetailModel?;
        orderDetail.value = details;
        _syncPartnerAvatarCache(details);

        final updatedOrder = results[1] as HistoryOrderModel?;
        if (updatedOrder != null) {
          _historyOrder.value = updatedOrder;
          _syncVoucherController(updatedOrder.voucher?.code);

          // Sync back to ClientOrderController's history list if it exists
          if (Get.isRegistered<ClientOrderController>()) {
            final listController = Get.find<ClientOrderController>();
            final index = listController.historyOrders.indexWhere((o) => o.id == updatedOrder.id);
            if (index != -1) {
              listController.historyOrders[index] = updatedOrder;
            }
          }
        }
      } else {
        // For current orders: fetch order details + the order itself in parallel
        final results = await Future.wait([
          _repository.getOrderDetails(orderId),
          _repository.getOrder(orderId),
        ]);

        final details = results[0] as OrderDetailModel?;
        orderDetail.value = details;
        _syncPartnerAvatarCache(details);

        final updatedOrder = results[1] as EventOrderModel?;
        if (updatedOrder != null) {
          _eventOrder.value = updatedOrder;
          _syncVoucherController(updatedOrder.voucher?.code);

          // Sync back to ClientOrderController's event orders list if it exists
          if (Get.isRegistered<ClientOrderController>()) {
            final listController = Get.find<ClientOrderController>();
            final index = listController.eventOrders.indexWhere(
              (o) => o.id == updatedOrder.id,
            );
            if (index != -1) {
              listController.eventOrders[index] = updatedOrder;
            }
          }
        }
      }
    } catch (e) {
      logger.e('Error fetching order details: $e');
    } finally {
      if (showLoading) isLoadingDetails.value = false;
      refreshController.refreshCompleted();
    }
  }

  void onRefresh() async {
    await fetchOrderDetails();
  }

  Future<void> choosePartner({
    required int partnerId,
    required double amount,
    required String partnerName,
  }) async {
    final context = Get.context!;
    String? finalVoucherCode = ClientOrderDetailState.savedVouchers[orderId]?.code;
    double? discountValue;

    if (finalVoucherCode != null && finalVoucherCode.isNotEmpty) {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.white)),
        barrierDismissible: false,
      );
      try {
        final result = await _repository.checkVoucherDiscount(
          orderId: orderId,
          partnerId: partnerId,
          voucherInput: finalVoucherCode,
        );
        if (Get.isDialogOpen == true) Get.back();

        if (result['status'] == true && result['discount'] != null) {
          final dynDiscount = result['discount'];
          if (dynDiscount is num && dynDiscount > 0) {
            discountValue = dynDiscount.toDouble();
          } else {
            finalVoucherCode = null;
          }
        } else {
          finalVoucherCode = null;
        }
      } catch (e) {
        if (Get.isDialogOpen == true) Get.back();
        finalVoucherCode = null;
        logger.e('Error checking voucher discount: $e');
      }
    }

    final confirmed = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          width: Get.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'confirm_choose_partner_title'.trParams({
                            'name': partnerName,
                          }),
                          style: context.typography.lg.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: context.typography.sm.copyWith(
                              color: Colors.black,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: 'confirm_choose_partner_desc'.tr,
                              ),
                              const TextSpan(text: '\n'),
                              TextSpan(text: 'partner_proposed_price_label'.tr),
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '${NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(amount)} đ',
                                  ),
                                  if (discountValue != null) ...[
                                    TextSpan(
                                      text: '\n${'discount_from_voucher'.tr}',
                                    ),
                                    TextSpan(
                                      text:
                                          '${NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(amount - discountValue)} đ (-${NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(discountValue)} đ)',
                                    ),
                                  ],
                                ],
                                style: const TextStyle(
                                  color: Color(0xFFC62828), // Colors.red[800]
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const TextSpan(text: '\n'),
                              TextSpan(text: 'accept_price_question'.tr),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Get.back(result: false),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(result: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text('confirm_no_btn'.tr),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FTheme.of(context).colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'confirm_yes_btn'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    isChoosingPartner.value = true;
    try {
      final result = await _repository.choosePartner(
        orderId: orderId,
        partnerId: partnerId,
        voucherCode: finalVoucherCode,
      );

      if (result['success'] == true) {
        Get.snackbar('success'.tr, 'choose_partner_success'.tr);

        if (Get.isRegistered<ClientHomeController>()) {
          final applicantCount = _eventOrder.value?.applicantCount ?? 0;
          Get.find<ClientHomeController>().confirmOrder(
            applicantCount: applicantCount,
          );
        }

        await fetchOrderDetails();
        if (Get.isRegistered<MessageController>()) {
          await Get.find<MessageController>().refreshThreads();
        }
      } else {
        Get.snackbar(
          'error'.tr,
          result['message'] ?? 'choose_partner_failed'.tr,
          backgroundColor: const Color(0xFFFFEBEE), // Colors.red[50]
          colorText: const Color(0xFFB71C1C), // Colors.red[900]
        );
      }
    } catch (e) {
      logger.e('Error choosing partner: $e');
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isChoosingPartner.value = false;
    }
  }

  Future<void> cancelOrder() async {
    final context = Get.context!;
    final confirmed = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          width: Get.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'confirm_cancel_order_title'.tr,
                          style: context.typography.lg.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: context.typography.sm.copyWith(
                              color: Colors.black,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: 'confirm_cancel_order_desc'.tr,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Get.back(result: false),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(result: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    child: Text('cancel_order_no_btn'.tr),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FTheme.of(context).colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    child: Text(
                      'cancel_order_yes_btn'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    isCancellingOrder.value = true;
    try {
      final result = await _repository.cancelOrder(orderId);

      if (result['success'] == true) {
        Get.snackbar('success'.tr, 'cancel_success'.tr);
        await fetchOrderDetails(); // Refresh to reflect cancelled status

        // Trigger history reload in ClientOrderController if it's registered
        if (Get.isRegistered<ClientOrderController>()) {
          final listController = Get.find<ClientOrderController>();
          listController.hasFetchedHistory.value = false;
          listController.fetchHistoryOrders();
        }
      } else {
        Get.snackbar(
          'error'.tr,
          result['message'] ?? 'cancel_failed'.tr,
          backgroundColor: const Color(0xFFFFEBEE), // Colors.red[50]
          colorText: const Color(0xFFB71C1C), // Colors.red[900]
        );
      }
    } catch (e) {
      logger.e('Error cancelling order: $e');
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isCancellingOrder.value = false;
    }
  }

  Future<void> submitReview(int partnerId) async {
    if (rating.value == 0) {
      Get.snackbar('error'.tr, 'please_select_rating'.tr);
      return;
    }

    isSubmittingReview.value = true;
    try {
      final comment = reviewCommentController.text.trim();
      final result = await _repository.submitReview(
        orderId: orderId,
        partnerId: partnerId,
        rating: rating.value,
        comment: comment.isEmpty ? null : comment,
      );

      if (result['success'] == true) {
        Get.back(); // Close bottom sheet
        Get.snackbar(
          'success'.tr,
          result['message'] ?? 'review_submitted_success'.tr,
        );
        await fetchOrderDetails();
      } else {
        Get.snackbar(
          'error'.tr,
          result['message'] ?? 'submit_review_failed'.tr,
          backgroundColor: const Color(0xFFFFEBEE), // Colors.red[50]
          colorText: const Color(0xFFB71C1C), // Colors.red[900]
        );
      }
    } catch (e) {
      logger.e('Error submitting review: $e');
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isSubmittingReview.value = false;
    }
  }

  Future<void> checkVoucher() async {
    final code = voucherController.text.trim();
    if (code.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'please_enter_voucher_code'.tr,
        backgroundColor: const Color(0xFFFFEBEE),
        colorText: const Color(0xFFB71C1C),
      );
      return;
    }

    isCheckingVoucher.value = true;
    try {
      final result = await _repository.validateVoucher(
        orderId: orderId,
        voucherInput: code,
      );

      if (result['status'] == true && result['details'] != null) {
        final voucher = VoucherModel.fromJson(result['details']);
        ClientOrderDetailState.savedVouchers[orderId] = voucher;
        showVoucherResultBottomSheet(voucher);
      } else {
        Get.snackbar(
          'error'.tr,
          result['message'] ?? 'fetch_failed'.tr,
          backgroundColor: const Color(0xFFFFEBEE),
          colorText: const Color(0xFFB71C1C),
        );
      }
    } catch (e) {
      logger.e('Error checking voucher: $e');
      Get.snackbar('error'.tr, 'network_error'.tr);
    } finally {
      isCheckingVoucher.value = false;
    }
  }

  Future<void> removeVoucher() async {
    final savedVoucher = ClientOrderDetailState.savedVouchers[orderId];
    if (savedVoucher == null && usedVoucherCode == null) {
      voucherController.clear();
      return;
    }

    isRemovingVoucher.value = true;
    try {
      final result = await _repository.removeVoucher(orderId: orderId);
      final bool success = result['success'] == true || result['status'] == true;

      if (success) {
        ClientOrderDetailState.savedVouchers.remove(orderId);
        voucherController.clear();
        Get.snackbar(
          'success'.tr,
          result['message'] ?? 'remove_voucher_success'.tr,
        );
        await fetchOrderDetails(showLoading: false);
      } else {
        Get.snackbar(
          'error'.tr,
          result['message'] ?? 'remove_voucher_failed'.tr,
          backgroundColor: const Color(0xFFFFEBEE),
          colorText: const Color(0xFFB71C1C),
        );
      }
    } catch (e) {
      logger.e('Error removing voucher: $e');
      Get.snackbar('error'.tr, 'network_error'.tr);
    } finally {
      isRemovingVoucher.value = false;
    }
  }

  void showVoucherResultBottomSheet(VoucherModel voucher) {
    Get.bottomSheet(
      VoucherDetailsBottomSheet(voucher: voucher),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      ignoreSafeArea: false,
    );
  }

  Future<void> openPartnerProfilePreview(int userId) async {
    activePreviewUserId.value = userId;
    profilePreviewError.value = '';
    activeProfilePreviewAvatarUrl.value = _cachedProfileAvatarUrl(userId) ?? '';

    final PublicProfilePreviewModel? cached = profilePreviewCache[userId];
    activeProfilePreview.value = cached;
    _refreshActiveProfilePreviewAvatarUrl(userId);
    isProfilePreviewLoading.value = cached == null;

    if (Get.isDialogOpen != true) {
      Get.dialog(
        Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          child: Obx(
            () => ProfilePreviewModal(
              profile: activeProfilePreview.value,
              avatarUrl: activeProfilePreviewAvatarUrl.value,
              isLoading: isProfilePreviewLoading.value,
              errorMessage: profilePreviewError.value,
              onClose: Get.back,
              onRetry: retryPartnerProfilePreview,
            ),
          ),
        ),
        barrierDismissible: true,
      );
    }

    if (cached != null) return;
    await _fetchPartnerProfilePreview(userId);
  }

  Future<void> retryPartnerProfilePreview() async {
    final int? userId = activePreviewUserId.value;
    if (userId == null) return;
    await _fetchPartnerProfilePreview(userId, forceRefresh: true);
  }

  Future<void> _fetchPartnerProfilePreview(
    int userId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && profilePreviewCache.containsKey(userId)) {
      activeProfilePreview.value = profilePreviewCache[userId];
      _refreshActiveProfilePreviewAvatarUrl(userId);
      profilePreviewError.value = '';
      isProfilePreviewLoading.value = false;
      return;
    }

    isProfilePreviewLoading.value = true;
    profilePreviewError.value = '';

    try {
      final PublicProfilePreviewModel profile = await _profileRepository
          .getPublicProfilePreview(userId);
      profilePreviewCache[userId] = profile;

      if (activePreviewUserId.value == userId) {
        activeProfilePreview.value = profile;
        _refreshActiveProfilePreviewAvatarUrl(userId);
      }
    } catch (e) {
      logger.e('Error loading public profile preview for $userId: $e');
      if (activePreviewUserId.value == userId) {
        activeProfilePreview.value = null;
        _refreshActiveProfilePreviewAvatarUrl(userId);
        profilePreviewError.value = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      }
    } finally {
      if (activePreviewUserId.value == userId) {
        isProfilePreviewLoading.value = false;
      }
    }
  }

  void _syncPartnerAvatarCache(OrderDetailModel? details) {
    final Map<int, String> nextCache = <int, String>{};

    for (final OrderItemModel item
        in details?.items ?? const <OrderItemModel>[]) {
      final OrderPartnerModel? partner = item.partner;
      if (partner == null || partner.id == 0) continue;

      nextCache[partner.id] = avatarUrlForPartner(partner);
    }

    profileAvatarCache
      ..clear()
      ..addAll(nextCache);

    final int? activeUserId = activePreviewUserId.value;
    if (activeUserId != null) {
      _refreshActiveProfilePreviewAvatarUrl(activeUserId);
    }
  }

  String avatarUrlForPartner(OrderPartnerModel partner) {
    if (partner.avatar.isNotEmpty) return partner.avatar;

    final String encodedName = Uri.encodeComponent(partner.name);
    return 'https://ui-avatars.com/api/?name=$encodedName&background=random&size=512&format=png';
  }

  String? _cachedProfileAvatarUrl(int userId) {
    final String? cachedAvatarUrl = profileAvatarCache[userId];
    if (cachedAvatarUrl == null || cachedAvatarUrl.isEmpty) return null;
    return cachedAvatarUrl;
  }

  void _refreshActiveProfilePreviewAvatarUrl(int userId) {
    activeProfilePreviewAvatarUrl.value =
        _cachedProfileAvatarUrl(userId) ??
        activeProfilePreview.value?.payload.user.avatarUrl ??
        '';
  }
}
