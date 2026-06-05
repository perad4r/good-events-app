import 'package:dio/dio.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/core/utils/app_exceptions.dart';
import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/domain/api_url.dart';

class AuthProvider {
  final ApiService _apiService;

  AuthProvider(this._apiService);

  /// Login API call
  /// POST /auth/login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.dio.post(
        AppUrl.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Login failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      logger.e('[AuthProvider] [login] DioException: ${e.message}');

      if (e.response != null) {
        final code = e.response?.data['code'];
        if (e.response?.statusCode == 403 && code == 'UNVERIFIED') {
          throw UnverifiedUserException(
            data: e.response!.data as Map<String, dynamic>,
          );
        }
        final errorMessage = e.response?.data['message'] ?? 'Login failed';
        throw Exception(errorMessage);
      } else {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra mạng.',
        );
      }
    } catch (e) {
      logger.e('[AuthProvider] [login] Unknown error: $e');
      rethrow;
    }
  }

  /// Google Login API call
  /// POST /login/google
  Future<Map<String, dynamic>> loginWithGoogle(String accessToken) async {
    try {
      final response = await _apiService.dio.post(
        AppUrl.loginGoogle,
        data: {'access_token': accessToken},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Google login failed with status: \${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      logger.e('[AuthProvider] [loginWithGoogle] DioException: \${e.message}');

      if (e.response != null) {
        final code = e.response?.data['code'];
        if (e.response?.statusCode == 403 && code == 'UNVERIFIED') {
          throw UnverifiedUserException(
            data: e.response!.data as Map<String, dynamic>,
          );
        }
        final errorMessage =
            e.response?.data['message'] ?? 'Google login failed';
        throw Exception(errorMessage);
      } else {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra mạng.',
        );
      }
    } catch (e) {
      logger.e('[AuthProvider] [loginWithGoogle] Unknown error: $e');
      throw Exception('Đã xảy ra lỗi: $e');
    }
  }

  /// Apple Login API call
  /// POST /auth/apple
  Future<Map<String, dynamic>> loginWithApple({
    required String identityToken,
    required String authorizationCode,
    String? email,
    String? givenName,
    String? familyName,
  }) async {
    try {
      final response = await _apiService.dio.post(
        AppUrl.loginApple,
        data: {
          'identity_token': identityToken,
          'authorization_code': authorizationCode,
          if (email != null && email.isNotEmpty) 'email': email,
          if (givenName != null && givenName.isNotEmpty)
            'given_name': givenName,
          if (familyName != null && familyName.isNotEmpty)
            'family_name': familyName,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Apple login failed with status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      logger.e('[AuthProvider] [loginWithApple] DioException: ${e.message}');

      if (e.response != null) {
        final code = e.response?.data['code'];
        if (e.response?.statusCode == 403 && code == 'UNVERIFIED') {
          throw UnverifiedUserException(
            data: e.response!.data as Map<String, dynamic>,
          );
        }
        final errorMessage =
            e.response?.data['message'] ?? 'Apple login failed';
        throw Exception(errorMessage);
      } else {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra mạng.',
        );
      }
    } catch (e) {
      logger.e('[AuthProvider] [loginWithApple] Unknown error: $e');
      throw Exception('Đã xảy ra lỗi: $e');
    }
  }

  /// Client Registration API call
  /// POST /register
  Future<Map<String, dynamic>> registerClient(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.post(
        AppUrl.registerClient,
        data: data,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Registration failed with status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      logger.e('[AuthProvider] [registerClient] DioException: ${e.message}');
      if (e.response != null) {
        _throwIfPasswordValidationError(e.response!.data);
        final errorMessage =
            e.response?.data['message'] ?? 'Registration failed';
        throw Exception(errorMessage);
      } else {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra mạng.',
        );
      }
    } catch (e) {
      logger.e('[AuthProvider] [registerClient] Unknown error: $e');
      throw Exception('Đã xảy ra lỗi: $e');
    }
  }

  /// Partner Registration API call
  /// POST /register/partner
  Future<Map<String, dynamic>> registerPartner(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.dio.post(
        AppUrl.registerPartner,
        data: data,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Registration failed with status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      logger.e('[AuthProvider] [registerPartner] DioException: ${e.message}');
      if (e.response != null) {
        _throwIfPasswordValidationError(e.response!.data);
        final errorMessage =
            e.response?.data['message'] ?? 'Registration failed';
        throw Exception(errorMessage);
      } else {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra mạng.',
        );
      }
    } catch (e) {
      logger.e('[AuthProvider] [registerPartner] Unknown error: $e');
      throw Exception('Đã xảy ra lỗi: $e');
    }
  }

  /// Checks [responseData] for `errors.password` from a 422 Laravel response
  /// and throws [PasswordValidationException] when password error codes are found.
  void _throwIfPasswordValidationError(dynamic responseData) {
    if (responseData is! Map) return;
    final errors = responseData['errors'];
    if (errors is! Map) return;
    final passwordErrors = errors['password'];
    if (passwordErrors is! List || passwordErrors.isEmpty) return;
    final codes = passwordErrors.whereType<String>().toList();
    if (codes.isNotEmpty) {
      throw PasswordValidationException(codes);
    }
  }

  /// Check Token Validity API call
  /// GET /check-token
  Future<Map<String, dynamic>?> checkToken() async {
    try {
      final response = await _apiService.dio.get(AppUrl.checkToken);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        return null;
      }
    } on DioException catch (e) {
      logger.e('[AuthProvider] [checkToken] DioException: ${e.message}');

      if (e.response?.statusCode == 401) {
        return null;
      }

      if (e.response?.statusCode == 403 &&
          e.response?.data['code'] == 'UNVERIFIED') {
        throw UnverifiedUserException(
          data: e.response!.data as Map<String, dynamic>,
        );
      }

      throw Exception('Không thể xác thực token. Vui lòng thử lại.');
    } catch (e) {
      logger.e('[AuthProvider] [checkToken] Unknown error: $e');
      throw Exception('Đã xảy ra lỗi khi kiểm tra token: $e');
    }
  }

  Future<bool> logout() async {
    try {
      final response = await _apiService.dio.get(AppUrl.logout);

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } on DioException catch (e) {
      logger.e('[AuthProvider] [logout] DioException: ${e.message}');

      if (e.response?.statusCode == 401) {
        return false;
      }

      throw Exception('Không thể đăng xuất. Vui lòng thử lại.');
    } catch (e) {
      logger.e('[AuthProvider] [logout] Unknown error: $e');
      throw Exception('Đã xảy ra lỗi khi đăng xuất: $e');
    }
  }

  /// Send OTP API call
  /// POST /verify/send-otp
  Future<void> sendOtp(String method) async {
    try {
      final response = await _apiService.dio.post(
        AppUrl.verifySendOtp,
        data: {'method': method},
      );
      if (response.statusCode != 200) {
        throw Exception('Send OTP failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      logger.e('[AuthProvider] [sendOtp] DioException: ${e.message}');
      if (e.response != null) {
        final code = e.response?.data['code'];
        if (e.response?.statusCode == 429) {
          if (code == 'OTP_COOLDOWN') {
            final retryAfter = e.response?.data['retry_after'] as int?;
            throw OtpCooldownException(retryAfter: retryAfter);
          }
          if (code == 'MAX_ATTEMPTS') {
            throw const OtpMaxAttemptsException();
          }
        }
        final errorMessage = e.response?.data['message'] ?? 'Send OTP failed';
        throw Exception(errorMessage);
      } else {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra mạng.',
        );
      }
    } catch (e) {
      logger.e('[AuthProvider] [sendOtp] Unknown error: $e');
      rethrow;
    }
  }

  /// Verify OTP (Phone) API call
  /// POST /verify/otp
  Future<void> verifyOtp(String otp) async {
    try {
      final response = await _apiService.dio.post(
        AppUrl.verifyOtp,
        data: {'otp': otp},
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Verify OTP failed with status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      logger.e('[AuthProvider] [verifyOtp] DioException: ${e.message}');
      if (e.response != null) {
        final code = e.response?.data['code'];
        if (e.response?.statusCode == 429) {
          if (code == 'OTP_COOLDOWN') {
            final retryAfter = e.response?.data['retry_after'] as int?;
            throw OtpCooldownException(retryAfter: retryAfter);
          }
          if (code == 'MAX_ATTEMPTS') {
            throw const OtpMaxAttemptsException();
          }
        }
        if (e.response?.statusCode == 422 && code == 'INVALID_OTP') {
          throw const OtpInvalidException();
        }
        final errorMessage = e.response?.data['message'] ?? 'Invalid OTP';
        throw Exception(errorMessage);
      } else {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra mạng.',
        );
      }
    } catch (e) {
      logger.e('[AuthProvider] [verifyOtp] Unknown error: $e');
      rethrow;
    }
  }

  /// Forgot password – send OTP (phone) or reset email (email)
  /// POST /forgot/send
  /// Body: { method: 'phone'|'email', credential: <value> }
  Future<void> forgotSendOtp({
    required String method,
    required String credential,
  }) async {
    try {
      final response = await _apiService.dio.post(
        AppUrl.forgotSend,
        data: {'method': method, 'credential': credential},
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Forgot send failed with status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      logger.e('[AuthProvider] [forgotSendOtp] DioException: ${e.message}');
      if (e.response != null) {
        final code = e.response?.data['code'];
        if (e.response?.statusCode == 404 && code == 'USER_NOT_FOUND') {
          throw const UserNotFoundException();
        }
        if (e.response?.statusCode == 429) {
          if (code == 'OTP_COOLDOWN') {
            final retryAfter = e.response?.data['seconds'] as int?;
            throw OtpCooldownException(retryAfter: retryAfter);
          }
          if (code == 'MAX_ATTEMPTS') {
            final retryAfter = e.response?.data['hours'] as int?;
            throw OtpMaxAttemptsException(retryAfter: retryAfter);
          }
        }
        final errorMessage =
            e.response?.data['message'] ?? 'Forgot send failed';
        throw Exception(errorMessage);
      } else {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra mạng.',
        );
      }
    } catch (e) {
      logger.e('[AuthProvider] [forgotSendOtp] Unknown error: $e');
      rethrow;
    }
  }

  /// Forgot password – verify OTP
  /// POST /forgot/verify-otp
  /// Body: { phone: <value>, otp: <value> }
  /// Returns reset_token on success.
  Future<String> forgotVerifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await _apiService.dio.post(
        AppUrl.forgotVerifyOtp,
        data: {'phone': phone, 'otp': otp},
      );
      if (response.statusCode == 200) {
        return response.data['reset_token'] as String;
      }
      throw Exception(
        'Forgot verify OTP failed with status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      logger.e('[AuthProvider] [forgotVerifyOtp] DioException: ${e.message}');
      if (e.response != null) {
        final code = e.response?.data['code'];
        if (e.response?.statusCode == 422 && code == 'INVALID_OTP') {
          throw const OtpInvalidException();
        }
        final errorMessage =
            e.response?.data['message'] ?? 'Verify OTP failed';
        throw Exception(errorMessage);
      } else {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra mạng.',
        );
      }
    } catch (e) {
      logger.e('[AuthProvider] [forgotVerifyOtp] Unknown error: $e');
      rethrow;
    }
  }

  /// Forgot password – reset password with token
  /// POST /forgot/reset-password
  /// Body: { reset_token: <token>, password: <newPassword> }
  Future<void> forgotResetPassword({
    required String resetToken,
    required String password,
  }) async {
    try {
      final response = await _apiService.dio.post(
        AppUrl.forgotResetPassword,
        data: {
          'reset_token': resetToken,
          'password': password,
          'password_confirmation': password,
        },
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Reset password failed with status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      logger.e(
        '[AuthProvider] [forgotResetPassword] DioException: ${e.message}',
      );
      if (e.response != null) {
        _throwIfPasswordValidationError(e.response!.data);
        final code = e.response?.data['code'];
        if (e.response?.statusCode == 422) {
          if (code == 'INVALID_TOKEN') throw const InvalidTokenException();
          if (code == 'USER_NOT_FOUND') throw const UserNotFoundException();
        }
        final errorMessage =
            e.response?.data['message'] ?? 'Reset password failed';
        throw Exception(errorMessage);
      } else {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra mạng.',
        );
      }
    } catch (e) {
      logger.e('[AuthProvider] [forgotResetPassword] Unknown error: $e');
      rethrow;
    }
  }
}

