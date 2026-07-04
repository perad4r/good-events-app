import 'dart:async';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/common/public_profile_preview_model.dart';
import 'package:sukientotapp/data/models/client/event_order_model.dart';
import 'package:sukientotapp/data/models/client/history_order_model.dart';
import 'package:sukientotapp/data/models/client/order_detail_model.dart';
import 'package:sukientotapp/data/models/client/voucher_model.dart';
import 'package:sukientotapp/domain/repositories/common/my_profile_repository.dart';
import 'package:sukientotapp/domain/repositories/client/order_repository.dart';
import 'package:sukientotapp/features/client/home/controller.dart';
import 'package:sukientotapp/features/client/order/controller.dart';
import 'package:sukientotapp/features/common/message/controller.dart';
import '../widgets/profile_preview.dart';
import '../widgets/voucher_details_bottom_sheet.dart';

part 'state.dart';
part 'actions.dart';
part 'report.dart';

class ClientOrderDetailController extends GetxController
    with ClientOrderDetailState {
  final OrderRepository _repository;
  final MyProfileRepository _profileRepository;

  final RefreshController refreshController = RefreshController(
    initialRefresh: false,
  );

  ClientOrderDetailController(this._repository, this._profileRepository);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      final order = args['order'];
      isHistory.value = args['isHistory'] ?? false;
      _assignOrder(order);
    } else {
      _assignOrder(args);
    }
    _syncVoucherController(
      isHistory.value
          ? _historyOrder.value?.voucher?.code
          : _eventOrder.value?.voucher?.code,
    );

    // Auto-fetch if this is a current order (where applicant/bill details lie)
    if (!isHistory.value && orderId != 0) {
      fetchOrderDetails();
      _startPeriodicRefresh();
    }

    // Restore saved voucher text if available
    final savedVoucher = ClientOrderDetailState.savedVouchers[orderId];
    if (savedVoucher != null) {
      voucherController.text = savedVoucher.code;
    }

    // Clear saved voucher if user modifies the code to something else
    voucherController.addListener(() {
      final savedCode = ClientOrderDetailState.savedVouchers[orderId]?.code;
      if (savedCode != null && voucherController.text.trim() != savedCode) {
        ClientOrderDetailState.savedVouchers.remove(orderId);
      }
    });
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Seamlessly fetch data in the background without triggering loading spinners
      fetchOrderDetails(showLoading: false);
    });
  }

  void _assignOrder(dynamic order) {
    if (order is HistoryOrderModel) {
      isHistory.value = true;
      _historyOrder.value = order;
    } else if (order is EventOrderModel) {
      isHistory.value = false;
      _eventOrder.value = order;
    }
  }

  void _syncVoucherController(String? voucherCode) {
    final String code = voucherCode?.trim() ?? '';
    if (code.isEmpty) {
      if (ClientOrderDetailState.savedVouchers[orderId] == null &&
          voucherController.text.isNotEmpty) {
        voucherController.clear();
      }
      return;
    }
    if (voucherController.text.trim() == code) return;
    voucherController.text = code;
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    reportTitleController.dispose();
    reportDescriptionController.dispose();
    super.onClose();
  }
}
