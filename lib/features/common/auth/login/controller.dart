import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/core/utils/app_exceptions.dart';
import 'package:sukientotapp/core/utils/env_config.dart';
import 'package:sukientotapp/domain/repositories/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginController extends GetxController {
  final AuthRepository _authRepository;

  LoginController(this._authRepository);

  final loginFormKey = GlobalKey<FormState>();

  // TextEditingControllers for input fields
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;
  final isGoogleLoading = false.obs;
  final isAppleLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize();
    } catch (_) {
      // Already initialized
    }
  }

  @override
  void onClose() {
    super.onClose();
    usernameController.dispose();
    passwordController.dispose();
  }

  Future<void> loginWithGoogle() async {
    try {
      isGoogleLoading.value = true;

      final googleUser = await GoogleSignIn.instance.authenticate();
      final authorization = await googleUser.authorizationClient
          .authorizeScopes(['email', 'profile']);
      final accessToken = authorization.accessToken;

      final user = await _authRepository.loginWithGoogle(accessToken);
      Get.snackbar(
        'success'.tr,
        'login_successful'.trParams({'name': user.name}),
      );
      await PusherService.init();
      await NotificationService.syncTokenAfterLogin();
      await Future.delayed(const Duration(seconds: 1));

      final role = StorageService.readMapData(
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

          break;
        case 'partner':
          Get.offAllNamed(Routes.partnerHome);

          StorageService.writeStringData(
            key: LocalStorageKeys.currentUIView,
            value: 'partner',
          );

          break;
      }
    } on UnverifiedUserException {
      AppSnackbar.showWarning(message: 'account_unverified'.tr);
      await Future.delayed(const Duration(seconds: 2));
      Get.toNamed(
        Routes.userVerifyScreen,
        arguments: {
          'isClientUser':
              StorageService.readMapData(
                key: LocalStorageKeys.user,
                mapKey: 'role',
              ) ==
              'client',
        },
      );
    } catch (e) {
      AppSnackbar.showError(message: e.toString());
    } finally {
      isGoogleLoading.value = false;
    }
  }

  bool get canUseAppleLogin {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return EnvConfig.hasAppleSignInConfig;
    }

    return true;
  }

  Future<void> loginWithApple() async {
    if (!canUseAppleLogin) {
      Get.snackbar('error'.tr, 'apple_login_not_ready'.tr);
      return;
    }

    try {
      isAppleLoading.value = true;

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions:
            defaultTargetPlatform == TargetPlatform.android
            ? WebAuthenticationOptions(
                clientId: EnvConfig.appleServiceId,
                redirectUri: Uri.parse(EnvConfig.appleRedirectUri),
              )
            : null,
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw Exception('No identity token received');
      }

      final user = await _authRepository.loginWithApple(
        identityToken: identityToken,
        authorizationCode: credential.authorizationCode,
        email: credential.email,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );

      Get.snackbar(
        'success'.tr,
        'login_successful'.trParams({'name': user.name}),
      );
      await PusherService.init();
      await NotificationService.syncTokenAfterLogin();
      await Future.delayed(const Duration(seconds: 1));

      final role = StorageService.readMapData(
        key: LocalStorageKeys.user,
        mapKey: 'role',
      );
      switch (role) {
        case 'client':
          Get.offAllNamed(Routes.clientHome);
          break;
        case 'partner':
          Get.offAllNamed(Routes.partnerHome);
          break;
      }
    } on UnverifiedUserException {
      AppSnackbar.showWarning(message: 'account_unverified'.tr);
      await Future.delayed(const Duration(seconds: 2));
      Get.toNamed(
        Routes.userVerifyScreen,
        arguments: {
          'isClientUser':
              StorageService.readMapData(
                key: LocalStorageKeys.user,
                mapKey: 'role',
              ) ==
              'client',
        },
      );
    } catch (e) {
      AppSnackbar.showError(message: e.toString());
    } finally {
      isAppleLoading.value = false;
    }
  }

  Future<void> login() async {
    loginFormKey.currentState!.save();

    if (!loginFormKey.currentState!.validate()) {
      debugPrint('Login form is invalid');
      return;
    }

    try {
      isLoading.value = true;
      final user = await _authRepository.login(
        usernameController.text,
        passwordController.text,
      );
      Get.snackbar(
        'success'.tr,
        'login_successful'.trParams({'name': user.name}),
      );
      await PusherService.init();
      await NotificationService.syncTokenAfterLogin();
      await Future.delayed(const Duration(seconds: 1));

      var role = StorageService.readMapData(
        key: LocalStorageKeys.user,
        mapKey: 'role',
      );
      switch (role) {
        case 'client':
          Get.offAllNamed(Routes.clientHome);
          break;
        case 'partner':
          Get.offAllNamed(Routes.partnerHome);
          break;
      }
    } on UnverifiedUserException {
      AppSnackbar.showWarning(message: 'account_unverified'.tr);
      await Future.delayed(const Duration(seconds: 2));
      Get.toNamed(
        Routes.userVerifyScreen,
        arguments: {
          'isClientUser':
              StorageService.readMapData(
                key: LocalStorageKeys.user,
                mapKey: 'role',
              ) ==
              'client',
        },
      );
    } catch (e) {
      if (e.toString().toLowerCase().startsWith('exception:')) {
        AppSnackbar.showError(message: e.toString().substring(10).trim());
      } else {
        AppSnackbar.showError(message: e.toString());
      }
    } finally {
      isLoading.value = false;
    }
  }
}
