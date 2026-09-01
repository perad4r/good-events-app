import 'dart:async';

import 'package:sukientotapp/core/services/localstorage_service.dart';
import 'package:sukientotapp/core/services/pusher_service.dart';
import 'package:sukientotapp/core/utils/app_exceptions.dart';
import 'package:sukientotapp/core/utils/import/global.dart';

class AccountSuspensionHandler {
  AccountSuspensionHandler._();

  static bool _isHandling = false;

  static Future<void> handle(AccountSuspendedException error) async {
    if (_isHandling) return;
    _isHandling = true;

    StorageService.clearAllData();
    try {
      await PusherService.disconnect();
    } catch (exception, stackTrace) {
      logger.e(
        '[AccountSuspension] Failed to disconnect subscriptions',
        error: exception,
        stackTrace: stackTrace,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showBlockingDialog(error));
    });
  }

  static Future<void> _showBlockingDialog(
    AccountSuspendedException error,
  ) async {
    await Get.dialog<void>(
      PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Tài khoản đã bị tạm khóa'),
          content: Text(error.banReason),
          actions: [
            TextButton(
              onPressed: () {
                final isAlreadyOnLogin =
                    Get.currentRoute == Routes.loginScreen;
                Get.back<void>();
                _isHandling = false;

                if (isAlreadyOnLogin) return;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Get.offAllNamed(Routes.loginScreen);
                });
              },
              child: const Text('Về trang đăng nhập'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}
