import 'dart:async';

import 'package:dio/dio.dart';
// ignore: implementation_imports
import 'package:pretty_dio_logger/src/pretty_dio_logger.dart';
import 'package:dio_log/dio_log.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import 'package:sukientotapp/core/utils/env_config.dart';
import 'package:sukientotapp/core/services/localstorage_service.dart';
import 'package:sukientotapp/core/error_reporting/app_error_reporter.dart';
import 'package:sukientotapp/core/error_reporting/error_reporting_interceptor.dart';
import 'package:sukientotapp/core/services/account_suspension_handler.dart';
import 'package:sukientotapp/core/services/api_contract_error_mapper.dart';
import 'package:sukientotapp/core/utils/app_exceptions.dart';

class ApiService {
  late Dio _dio;
  final AppErrorReporter _errorReporter;

  static final String baseUrl = EnvConfig.apiBaseUrl;

  FutureOr<bool> _shouldRetry(DioException error, int attempt) {
    final data = error.response?.data;
    final code = data is Map ? data['code'] : null;
    final isOtpLimitError =
        error.response?.statusCode == 429 &&
        (code == 'OTP_COOLDOWN' || code == 'MAX_ATTEMPTS');

    if (isOtpLimitError ||
        code == 'ACCOUNT_SUSPENDED' ||
        code == 'PARTNER_WORKFLOW_LOCKED') {
      return false;
    }

    return RetryInterceptor.defaultRetryEvaluator(error, attempt);
  }

  ApiService({AppErrorReporter? errorReporter})
    : _errorReporter = errorReporter ?? AppErrorReporter.instance {
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
          final contractError = ApiContractErrorMapper.fromResponseData(
            e.response?.data,
          );
          if (contractError is AccountSuspendedException) {
            unawaited(AccountSuspensionHandler.handle(contractError));
          }
          if (contractError != null) {
            return handler.next(e.copyWith(error: contractError));
          }
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

    // Reports only errors that remain after the retry policy is exhausted.
    _dio.interceptors.add(ErrorReportingInterceptor(reporter: _errorReporter));

    //Logging interceptor
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        filter: (options, args) {
          if (_isCallEndpoint(options.path)) return false;
          //  return !options.uri.path.contains('posts');
          return !args.isResponse || !args.hasUint8ListData;
        },
      ),
    );
    _dio.interceptors.add(_SafeDioLogInterceptor());
  }

  Dio get dio => _dio;
}

bool _isCallEndpoint(String path) =>
    path.contains('/calls') || path.contains('/calls/');

class _SafeDioLogInterceptor extends Interceptor {
  final DioLogInterceptor _delegate = DioLogInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isCallEndpoint(options.path)) return handler.next(options);
    _delegate.onRequest(options, handler);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (_isCallEndpoint(response.requestOptions.path)) return handler.next(response);
    _delegate.onResponse(response, handler);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    if (_isCallEndpoint(error.requestOptions.path)) return handler.next(error);
    _delegate.onError(error, handler);
  }
}
