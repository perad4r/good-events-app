import 'package:dio/dio.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/domain/api_url.dart';

import 'auth/user_login_sheet.dart';
import 'dev_list_tile.dart';

class AuthActionsGroup extends StatelessWidget {
  const AuthActionsGroup({super.key});

  Future<void> _logout(BuildContext context) async {
    Get.back();

    try {
      if (!Get.isRegistered<ApiService>()) {
        Get.lazyPut<ApiService>(() => ApiService(), fenix: true);
      }

      if (StorageService.readData(key: LocalStorageKeys.token) == null) {
        Get.snackbar('Info', 'No user logged in');
        return;
      }

      final api = Get.find<ApiService>();

      final deviceId =
          StorageService.readData(key: LocalStorageKeys.pushDeviceId)
              as String?;
      final response = await api.dio.get(
        AppUrl.logout,
        queryParameters: {
          if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
        },
      );

      if (response.statusCode == 200) {
        StorageService.clearAllData();
        Get.snackbar('Success', 'Logged out');
        Get.offAllNamed(Routes.loginScreen);
      } else {
        Get.snackbar('Error', 'Logout failed');
      }
    } on DioException catch (e) {
      logger.e('[DevOverlay] [logout] DioException: ${e.message}');

      if (e.response?.statusCode == 401) {
        StorageService.clearAllData();
        Get.snackbar('Success', 'Logged out');
        Get.offAllNamed(Routes.loginScreen);
        return;
      }

      Get.snackbar('Error', 'Không thể đăng xuất. Vui lòng thử lại.');
    } catch (e) {
      logger.e('[DevOverlay] [logout] Unknown error: $e');
      Get.snackbar('Error', 'Đã xảy ra lỗi khi đăng xuất: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(Icons.verified_user_outlined, color: AppColors.primary),
        title: Text(
          'Auth Actions',
          style: (Theme.of(context).textTheme.titleMedium ?? const TextStyle())
              .copyWith(
                fontFamily: 'Lexend',
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
        ),
        children: [
          DevListTile(
            indented: true,
            icon: Icons.logout,
            title: 'Logout',
            onTap: () => _logout(context),
          ),
          DevListTile(
            indented: true,
            icon: Icons.supervised_user_circle_outlined,
            title: 'User Login',
            onTap: () {
              Get.bottomSheet(const UserLoginSheet());
            },
          ),
        ],
      ),
    );
  }
}
