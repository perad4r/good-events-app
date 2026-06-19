import 'dart:async';

import 'package:dio/dio.dart';
// ignore: implementation_imports
import 'package:pretty_dio_logger/src/pretty_dio_logger.dart';
import 'package:dio_log/dio_log.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import 'package:sukientotapp/core/utils/env_config.dart';
import 'package:sukientotapp/core/services/localstorage_service.dart';

class ApiService {
  late Dio _dio;

  static final String baseUrl = EnvConfig.apiBaseUrl;

  FutureOr<bool> _shouldRetry(DioException error, int attempt) {
    final data = error.response?.data;
    final code = data is Map ? data['code'] : null;
    final isOtpLimitError =
        error.response?.statusCode == 429 &&
        (code == 'OTP_COOLDOWN' || code == 'MAX_ATTEMPTS');

    if (isOtpLimitError) return false;

    return RetryInterceptor.defaultRetryEvaluator(error, attempt);
  }

  ApiService() {
    if (baseUrl.isEmpty || baseUrl == '') {
      throw Exception('API_BASE_URL is not set in environment variables');
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    //Authorization interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = StorageService.readData(key: LocalStorageKeys.token);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );

    //Smart retry interceptor
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        retries: 3,
        retryEvaluator: _shouldRetry,
        retryDelays: const [
          Duration(seconds: 3), // wait 3 sec before the first retry
          Duration(seconds: 3), // wait 3 sec before the second retry
          Duration(seconds: 3), // wait 3 sec before the third retry
        ],
      ),
    );

    //Logging interceptor
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        filter: (options, args) {
          //  return !options.uri.path.contains('posts');
          return !args.isResponse || !args.hasUint8ListData;
        },
      ),
    );
    _dio.interceptors.add(DioLogInterceptor());
  }

  Dio get dio => _dio;
}
