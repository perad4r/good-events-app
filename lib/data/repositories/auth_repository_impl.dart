import 'package:sukientotapp/data/models/user_model.dart';
import 'package:sukientotapp/data/providers/auth_provider.dart';
import 'package:sukientotapp/domain/repositories/auth_repository.dart';
import 'package:sukientotapp/core/utils/app_exceptions.dart';
import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/core/services/localstorage_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthProvider _authProvider;

  AuthRepositoryImpl(this._authProvider);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _authProvider.login(email, password);

      final token = response['token'] as String?;
      if (token != null) {
        StorageService.writeStringData(
          key: LocalStorageKeys.token,
          value: token,
        );
        logger.i('[AuthRepositoryImpl] [login] Token saved to storage');
      }

      final userData = response;
      final user = UserModel.fromJson(userData);

      StorageService.writeMapData(
        key: LocalStorageKeys.user,
        value: user.toJson(),
      );

      logger.i(
        '[AuthRepositoryImpl] [login] Login successful for user: ${user.email}',
      );
      return user;
    } on UnverifiedUserException catch (e) {
      final token = e.data['token'] as String?;
      if (token != null) {
        StorageService.writeStringData(
          key: LocalStorageKeys.token,
          value: token,
        );
      }

      final user = UserModel.fromJson(e.data);
      StorageService.writeMapData(
        key: LocalStorageKeys.user,
        value: user.toJson(),
      );

      logger.w(
        '[AuthRepositoryImpl] [login] User unverified: ${user.email}',
      );
      rethrow;
    } catch (e) {
      logger.e('[AuthRepositoryImpl] [login] Login failed: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel> loginWithGoogle(String accessToken) async {
    try {
      final response = await _authProvider.loginWithGoogle(accessToken);

      final token = response['token'] as String?;
      if (token != null) {
        StorageService.writeStringData(
          key: LocalStorageKeys.token,
          value: token,
        );
        logger.i(
          '[AuthRepositoryImpl] [loginWithGoogle] Token saved to storage',
        );
      }

      final user = UserModel.fromJson(response);
      StorageService.writeMapData(
        key: LocalStorageKeys.user,
        value: user.toJson(),
      );

      logger.i(
        '[AuthRepositoryImpl] [loginWithGoogle] Login successful for: \${user.email}',
      );
      return user;
    } on UnverifiedUserException catch (e) {
      final token = e.data['token'] as String?;
      if (token != null) {
        StorageService.writeStringData(
          key: LocalStorageKeys.token,
          value: token,
        );
      }

      final user = UserModel.fromJson(e.data);
      StorageService.writeMapData(
        key: LocalStorageKeys.user,
        value: user.toJson(),
      );

      logger.w(
        '[AuthRepositoryImpl] [loginWithGoogle] User unverified: ${user.email}',
      );
      rethrow;
    } catch (e) {
      logger.e('[AuthRepositoryImpl] [loginWithGoogle] Failed: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel> loginWithApple({
    required String identityToken,
    required String authorizationCode,
    String? email,
    String? givenName,
    String? familyName,
  }) async {
    try {
      final response = await _authProvider.loginWithApple(
        identityToken: identityToken,
        authorizationCode: authorizationCode,
        email: email,
        givenName: givenName,
        familyName: familyName,
      );

      final token = response['token'] as String?;
      if (token != null) {
        StorageService.writeStringData(
          key: LocalStorageKeys.token,
          value: token,
        );
        logger.i(
          '[AuthRepositoryImpl] [loginWithApple] Token saved to storage',
        );
      }

      final user = UserModel.fromJson(response);
      StorageService.writeMapData(
        key: LocalStorageKeys.user,
        value: user.toJson(),
      );

      logger.i(
        '[AuthRepositoryImpl] [loginWithApple] Login successful for: ${user.email}',
      );
      return user;
    } on UnverifiedUserException catch (e) {
      final token = e.data['token'] as String?;
      if (token != null) {
        StorageService.writeStringData(
          key: LocalStorageKeys.token,
          value: token,
        );
      }

      final user = UserModel.fromJson(e.data);
      StorageService.writeMapData(
        key: LocalStorageKeys.user,
        value: user.toJson(),
      );

      logger.w(
        '[AuthRepositoryImpl] [loginWithApple] User unverified: ${user.email}',
      );
      rethrow;
    } catch (e) {
      logger.e('[AuthRepositoryImpl] [loginWithApple] Failed: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel> registerClient(Map<String, dynamic> data) async {
    try {
      final response = await _authProvider.registerClient(data);

      final token = response['token'] as String?;
      if (token != null) {
        StorageService.writeStringData(
          key: LocalStorageKeys.token,
          value: token,
        );
        logger.i(
          '[AuthRepositoryImpl] [registerClient] Token saved to storage',
        );
      }

      final user = UserModel.fromJson(response);
      StorageService.writeMapData(
        key: LocalStorageKeys.user,
        value: user.toJson(),
      );

      logger.i(
        '[AuthRepositoryImpl] [registerClient] Registration successful for: ${user.email}',
      );
      return user;
    } catch (e) {
      logger.e('[AuthRepositoryImpl] [registerClient] Failed: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel> registerPartner(Map<String, dynamic> data) async {
    try {
      final response = await _authProvider.registerPartner(data);

      final token = response['token'] as String?;
      if (token != null) {
        StorageService.writeStringData(
          key: LocalStorageKeys.token,
          value: token,
        );
        logger.i(
          '[AuthRepositoryImpl] [registerPartner] Token saved to storage',
        );
      }

      final user = UserModel.fromJson(response);
      StorageService.writeMapData(
        key: LocalStorageKeys.user,
        value: user.toJson(),
      );

      logger.i(
        '[AuthRepositoryImpl] [registerPartner] Registration successful for: ${user.email}',
      );
      return user;
    } catch (e) {
      logger.e('[AuthRepositoryImpl] [registerPartner] Failed: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> checkToken() async {
    try {
      logger.i('[AuthRepositoryImpl] [checkToken] Checking token validity');

      final result = await _authProvider.checkToken();

      if (result != null && result['valid'] == true) {
        logger.i('[AuthRepositoryImpl] [checkToken] Token is valid');
      } else {
        logger.w(
          '[AuthRepositoryImpl] [checkToken] Token is invalid or expired',
        );
      }

      return result;
    } catch (e) {
      logger.e('[AuthRepositoryImpl] [checkToken] Check token failed: $e');
      rethrow;
    }
  }

  @override
  Future<bool> logout() async {
    try {
      logger.i('[AuthRepositoryImpl] [logout] Logging out user');

      // Clear stored data no matter what response is
      StorageService.clearAllData();

      logger.i('[AuthRepositoryImpl] [logout] User logged out successfully');
      return true;
    } catch (e) {
      logger.e('[AuthRepositoryImpl] [logout] Logout failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendOtp(String method) async {
    try {
      logger.i('[AuthRepositoryImpl] [sendOtp] Sending OTP via $method');
      await _authProvider.sendOtp(method);
      logger.i('[AuthRepositoryImpl] [sendOtp] OTP sent successfully');
    } catch (e) {
      logger.e('[AuthRepositoryImpl] [sendOtp] Failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> verifyOtp(String otp) async {
    try {
      logger.i('[AuthRepositoryImpl] [verifyOtp] Verifying OTP');
      await _authProvider.verifyOtp(otp);
      logger.i('[AuthRepositoryImpl] [verifyOtp] OTP verified successfully');
    } catch (e) {
      logger.e('[AuthRepositoryImpl] [verifyOtp] Failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> forgotSendOtp({
    required String method,
    required String credential,
  }) async {
    try {
      logger.i(
        '[AuthRepositoryImpl] [forgotSendOtp] Sending via $method',
      );
      await _authProvider.forgotSendOtp(
        method: method,
        credential: credential,
      );
      logger.i('[AuthRepositoryImpl] [forgotSendOtp] Sent successfully');
    } catch (e) {
      logger.e('[AuthRepositoryImpl] [forgotSendOtp] Failed: $e');
      rethrow;
    }
  }

  @override
  Future<String> forgotVerifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      logger.i('[AuthRepositoryImpl] [forgotVerifyOtp] Verifying OTP for $phone');
      final token = await _authProvider.forgotVerifyOtp(
        phone: phone,
        otp: otp,
      );
      logger.i('[AuthRepositoryImpl] [forgotVerifyOtp] Verified, token received');
      return token;
    } catch (e) {
      logger.e('[AuthRepositoryImpl] [forgotVerifyOtp] Failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> forgotResetPassword({
    required String resetToken,
    required String password,
  }) async {
    try {
      logger.i('[AuthRepositoryImpl] [forgotResetPassword] Resetting password');
      await _authProvider.forgotResetPassword(
        resetToken: resetToken,
        password: password,
      );
      logger.i('[AuthRepositoryImpl] [forgotResetPassword] Password reset successfully');
    } catch (e) {
      logger.e('[AuthRepositoryImpl] [forgotResetPassword] Failed: $e');
      rethrow;
    }
  }
}
