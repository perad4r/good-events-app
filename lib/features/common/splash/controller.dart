import 'dart:async';

import 'package:sukientotapp/core/utils/app_exceptions.dart';
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/core/utils/app_videos.dart';
import 'package:sukientotapp/domain/repositories/auth_repository.dart';
import 'package:sukientotapp/domain/repositories/settings_repository.dart';
import 'package:video_player/video_player.dart';

class SplashController extends GetxController {
  final AuthRepository _authRepository;
  final SettingsRepository _settingsRepository;

  SplashController(this._authRepository, this._settingsRepository);

  VideoPlayerController videoPlayerController = VideoPlayerController.asset(
    AppVideos.splashVideoLight,
  );
  RxBool isVideoInitialized = false.obs;

  // waits for video to complete
  final Completer<void> _videoCompleter = Completer<void>();
  bool _skipRequested = false;
  bool _videoDisposed = false;

  final bool isDarkMode = Get.isDarkMode;

  @override
  void onInit() {
    super.onInit();

    // Apply saved locale if any
    final saved = StorageService.readMapData(key: LocalStorageKeys.locale);
    if (saved is Map<String, dynamic>) {
      final code = (saved['languageCode'] ?? 'vi') as String;
      final country =
          (saved['countryCode'] ?? (code == 'vi' ? 'VN' : 'US')) as String;
      Get.updateLocale(Locale(code, country));
    }

    _initVideo();
    _fetchSettings();
    _checkToken();
  }

  @override
  void onClose() {
    /// mem leak ;)
    if (!_videoDisposed) {
      videoPlayerController.dispose();
      _videoDisposed = true;
    }
    super.onClose();
  }

  void skipIntro() {
    if (_skipRequested) return;
    _skipRequested = true;

    if (!_videoCompleter.isCompleted) {
      _videoCompleter.complete();
    }

    // Hide video immediately to avoid binding a disposed controller in UI.
    if (isVideoInitialized.value) {
      isVideoInitialized.value = false;
    }

    try {
      videoPlayerController.pause();
    } catch (_) {}

    if (!_videoDisposed) {
      try {
        videoPlayerController.dispose();
      } catch (_) {}
      _videoDisposed = true;
    }
  }

  void _initVideo() async {
    // speeds up app opening in debug mode
    // if (kDebugMode) {
    //   _videoCompleter.complete();
    //   return;
    // }

    try {
      await videoPlayerController.initialize();
    } catch (e) {
      logger.w('[SplashController] [_initVideo] init failed: $e');
      if (!_videoCompleter.isCompleted) _videoCompleter.complete();
      return;
    }

    if (_skipRequested || _videoDisposed) {
      if (!_videoCompleter.isCompleted) _videoCompleter.complete();
      return;
    }

    isVideoInitialized.value = true;
    videoPlayerController.play();

    videoPlayerController.addListener(() {
      final pos = videoPlayerController.value.position;
      final dur = videoPlayerController.value.duration;
      if (dur > Duration.zero && pos >= dur) {
        if (!_videoCompleter.isCompleted) {
          _videoCompleter.complete();
        }
      }
    });

    // Fallback: if listener never fires (release mode codec issue), complete after duration + 2s
    final videoDuration = videoPlayerController.value.duration;
    if (videoDuration > Duration.zero) {
      Future.delayed(videoDuration + const Duration(seconds: 2), () {
        if (!_videoCompleter.isCompleted) {
          logger.w(
            '[SplashController] [_initVideo] Fallback timeout triggered',
          );
          _videoCompleter.complete();
        }
      });
    }
  }

  /// Fetch app settings from BE and cache to local storage
  Future<void> _fetchSettings() async {
    try {
      await _settingsRepository.fetchSettings();
    } catch (e) {
      logger.w('[SplashController] [_fetchSettings] Failed: $e');
    }
  }

  ///Check token validity
  Future<void> _checkToken() async {
    // Wait for video with an 8s safety timeout (release mode video may hang)
    await _videoCompleter.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        logger.w(
          '[SplashController] [_checkToken] Video timeout, continuing...',
        );
      },
    );

    final token = StorageService.readData(key: LocalStorageKeys.token);

    if (token == null) {
      logger.w(
        '[SplashController] [_checkToken] No token found, redirecting to choose side',
      );
      Get.offAllNamed(Routes.chooseYoSideScreen);
      return;
    }

    try {
      final result = await _authRepository.checkToken();
      final isTokenValid = result != null && result['valid'] == true;

      if (isTokenValid) {
        final isLegit = result['is_legit'];
        if (isLegit != null) {
          final existingUser =
              StorageService.readMapData(key: LocalStorageKeys.user) ??
              <String, dynamic>{};
          StorageService.writeMapData(
            key: LocalStorageKeys.user,
            value: {...existingUser, 'is_legit': isLegit},
          );
        }

        await PusherService.init().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            logger.w(
              '[SplashController] [_checkToken] Pusher init timed out, continuing...',
            );
          },
        );

        var role = StorageService.readMapData(
          key: LocalStorageKeys.user,
          mapKey: 'role',
        );
        switch (role) {
          case 'client':
            Get.offAllNamed(Routes.clientHome);

            StorageService.writeStringData(
              key: LocalStorageKeys.currentUIView,
              value: 'client',
            );

            return;
          case 'partner':
            Get.offAllNamed(Routes.partnerHome);

            StorageService.writeStringData(
              key: LocalStorageKeys.currentUIView,
              value: 'partner',
            );

            return;
        }
      } else {
        logger.w(
          '[SplashController] [_checkToken] Token invalid, clearing storage',
        );
        StorageService.removeData(key: LocalStorageKeys.token);
        StorageService.removeData(key: LocalStorageKeys.user);

        Get.offAllNamed(Routes.chooseYoSideScreen);
      }
    } on UnverifiedUserException {
      logger.w(
        '[SplashController] [_checkToken] Token valid but user unverified, redirecting to verify screen',
      );

      AppSnackbar.showWarning(message: 'account_unverified'.tr);
      await Future.delayed(const Duration(seconds: 2));
      Get.offAllNamed(Routes.userVerifyScreen);
    } catch (e) {
      StorageService.removeData(key: LocalStorageKeys.token);
      StorageService.removeData(key: LocalStorageKeys.user);
      Get.offAllNamed(Routes.chooseYoSideScreen);

      logger.e('[SplashController] [_checkToken] Error checking token: $e');
      AppSnackbar.showError(
        title: 'error'.tr,
        message: 'Đã xảy ra lỗi khi kiểm tra đăng nhập. Vui lòng thử lại.',
      );
    }
  }
}
