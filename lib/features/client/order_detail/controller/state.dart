part of 'controller.dart';

mixin ClientOrderDetailState {
  final Rx<EventOrderModel?> _eventOrder = Rx<EventOrderModel?>(null);
  final Rx<HistoryOrderModel?> _historyOrder = Rx<HistoryOrderModel?>(null);
  final RxBool isHistory = false.obs;

  // Details State
  final Rx<OrderDetailModel?> orderDetail = Rx<OrderDetailModel?>(null);
  final RxBool isLoadingDetails = false.obs;
  final RxBool isChoosingPartner = false.obs;
  final RxBool isCancellingOrder = false.obs;
  Timer? _refreshTimer;
  final RxBool isProfilePreviewLoading = false.obs;
  final RxString profilePreviewError = ''.obs;
  final RxnInt activePreviewUserId = RxnInt();
  final Rx<PublicProfilePreviewModel?> activeProfilePreview =
      Rx<PublicProfilePreviewModel?>(null);
  final Map<int, PublicProfilePreviewModel> profilePreviewCache =
      <int, PublicProfilePreviewModel>{};
  final RxString activeProfilePreviewAvatarUrl = ''.obs;
  final Map<int, String> profileAvatarCache = <int, String>{};

  // Report Form State
  final reportTitleController = TextEditingController();
  final reportDescriptionController = TextEditingController();
  final isSubmittingReport = false.obs;
  final reportErrors = <String, List<String>>{}.obs;

  // Review State
  final RxInt rating = 0.obs;
  final reviewCommentController = TextEditingController();
  final RxBool isSubmittingReview = false.obs;

  // Voucher State
  final voucherController = TextEditingController();
  final isCheckingVoucher = false.obs;
  static final savedVouchers = <int, VoucherModel>{}.obs;

  // Unified Getters
  int get orderId {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.id;
    }
    if (!isHistory.value && _eventOrder.value != null) {
      return _eventOrder.value!.id;
    }
    return 0;
  }

  String get orderCode {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.code ?? '';
    }
    if (!isHistory.value && _eventOrder.value != null) {
      return _eventOrder.value!.code;
    }
    return '';
  }

  String get categoryName {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.categoryName ?? '';
    }
    if (!isHistory.value && _eventOrder.value != null) {
      return _eventOrder.value!.categoryName;
    }
    return '';
  }

  String get parentCategoryName {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.parentCategoryName ?? '';
    }
    if (!isHistory.value && _eventOrder.value != null) {
      return _eventOrder.value!.parentCategoryName;
    }
    return '';
  }

  String get eventName {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.eventName ?? '';
    }
    if (!isHistory.value && _eventOrder.value != null) {
      return _eventOrder.value!.eventName;
    }
    return '';
  }

  String get status {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.status ?? '';
    }
    if (!isHistory.value && _eventOrder.value != null) {
      return _eventOrder.value!.status;
    }
    return '';
  }

  String get address {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.address ?? '';
    }
    if (!isHistory.value && _eventOrder.value != null) {
      return _eventOrder.value!.address;
    }
    return '';
  }

  String get date {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.date ?? '';
    }
    if (!isHistory.value && _eventOrder.value != null) {
      return _eventOrder.value!.date;
    }
    return '';
  }

  String get startTime {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.startTime ?? '';
    }
    if (!isHistory.value && _eventOrder.value != null) {
      return _eventOrder.value!.startTime;
    }
    return '';
  }

  String get endTime {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.endTime ?? '';
    }
    if (!isHistory.value && _eventOrder.value != null) {
      return _eventOrder.value!.endTime;
    }
    return '';
  }

  double get finalTotal {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.finalTotal?.toDouble() ??
          _historyOrder.value!.total?.toDouble() ??
          0.0;
    } else if (!isHistory.value && _eventOrder.value != null) {
      return _eventOrder.value!.finalTotal ?? 0.0;
    }
    return 0.0;
  }

  double get total {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.total?.toDouble() ?? 0.0;
    } else if (!isHistory.value && _eventOrder.value != null) {
      return _eventOrder.value!.finalTotal ?? 0.0;
    }
    return 0.0;
  }

  String get note {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.note ?? '';
    }
    if (!isHistory.value && _eventOrder.value != null) {
      return _eventOrder.value!.note;
    }
    return '';
  }

  String get createdAt {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.updatedAt ?? '';
    } else if (!isHistory.value && _eventOrder.value != null) {
      return '${_eventOrder.value!.date} ${_eventOrder.value!.startTime}';
    }
    return '';
  }

  String? get arrivalPhoto {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.arrivalPhoto;
    }
    if (!isHistory.value && _eventOrder.value != null) {
      return _eventOrder.value!.arrivalPhoto;
    }
    return null;
  }

  String? get completionPhoto {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.completionPhoto;
    }
    if (!isHistory.value && _eventOrder.value != null) {
      return _eventOrder.value!.completionPhoto;
    }
    return null;
  }

  String? get categoryImage {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.categoryImage;
    } else if (!isHistory.value && _eventOrder.value != null) {
      return _eventOrder.value!.categoryImage;
    }
    return null;
  }

  List<String> get bookingPhotos {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.bookingPhotos.take(5).toList(growable: false);
    }
    if (!isHistory.value && _eventOrder.value != null) {
      return _eventOrder.value!.bookingPhotos.take(5).toList(growable: false);
    }
    return const <String>[];
  }

  int? get partnerId {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.partner?.id;
    }
    if (!isHistory.value) {
      final items = orderDetail.value?.items ?? [];
      final chosen = items.where((i) => i.status == 'closed').firstOrNull;
      if (chosen != null) {
        return chosen.partner?.id;
      }
    }
    return null;
  }

  String get partnerAvatarUrl {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.partner?.avatarUrl ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_historyOrder.value!.partner?.name ?? '')}&background=random&size=512&format=png';
    }
    if (!isHistory.value) {
      final items = orderDetail.value?.items ?? [];
      final chosen = items.where((i) => i.status == 'closed').firstOrNull;
      if (chosen != null) {
        return chosen.partner?.avatar ??
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(chosen.partner?.name ?? '')}&background=random&size=512&format=png';
      }
    }
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(partnerName)}&background=random&size=512&format=png';
  }

  String get partnerName {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.partner?.partnerProfile?.partnerName ??
          _historyOrder.value!.partner?.name ??
          'partner_not_found'.tr;
    }
    if (!isHistory.value) {
      final items = orderDetail.value?.items ?? [];
      final chosen = items.where((i) => i.status == 'closed').firstOrNull;
      if (chosen != null) {
        return chosen.partner?.partnerProfile?.partnerName ??
            chosen.partner?.name ??
            'partner_not_found'.tr;
      }
    }
    return 'partner_not_found'.tr;
  }

  double? get partnerRating {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.partner?.statistics?.averageStars?.toDouble();
    }
    return null;
  }

  double? get partnerTotalRatings {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.partner?.statistics?.totalRatings?.toDouble();
    }
    return null;
  }

  bool get canChat {
    // For now, let's say we can chat if it's an active order (not history)
    // AND it has someone to chat with (confirmed or in_job)
    if (isHistory.value) return false;
    return status == 'confirmed' || status == 'in_job' || status == 'completed';
  }

  bool get canViewPartnerProfile {
    return !(isHistory.value && status == 'completed');
  }

  HistoryReviewModel? get review {
    if (isHistory.value && _historyOrder.value != null) {
      return _historyOrder.value!.review;
    }
    return null;
  }
}
