import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/data/models/client/asset_order_model.dart';

class ClientAssetOrderDetailController extends GetxController {
  late final AssetOrderModel _order;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is AssetOrderModel) {
      _order = args;
    } else {
      Get.back();
      return;
    }
  }

  // Getters
  int get orderId => _order.id;
  String get productName => _order.productName;
  String get categoryName => _order.categoryName;
  String get status => _order.status;
  String get statusLabel => _order.statusLabel;
  String get paymentMethod => _order.paymentMethod;
  String? get thumbnail => _order.thumbnail;
  String? get arrivalPhoto => _order.arrivalPhoto;
  String? get completionPhoto => _order.completionPhoto;
  double get total => _order.total;
  double? get tax => _order.tax;
  double? get finalTotal => _order.finalTotal;
  double get effectiveTotal => _order.effectiveTotal;
  bool get canDownload => _order.canDownload;
  bool get canRepay => _order.canRepay;

  String get formattedCreatedAt {
    try {
      final dt = DateTime.parse(_order.createdAt);
      return DateFormat('HH:mm • dd/MM/yyyy').format(dt);
    } catch (_) {
      return _order.createdAt;
    }
  }

  String get formattedUpdatedAt {
    try {
      final dt = DateTime.parse(_order.updatedAt);
      return DateFormat('HH:mm • dd/MM/yyyy').format(dt);
    } catch (_) {
      return _order.updatedAt;
    }
  }

  Color statusColor() {
    switch (status) {
      case 'paid':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
