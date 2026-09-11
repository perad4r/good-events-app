import 'dart:async';
import 'dart:collection';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sukientotapp/core/services/localstorage_service.dart';
import 'package:sukientotapp/core/utils/env_config.dart';
import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/domain/api_url.dart';

import 'app_error_report_request.dart';
import 'app_error_sanitizer.dart';
import 'app_error_types.dart';

class AppErrorReporter {
  AppErrorReporter._();

  static final AppErrorReporter instance = AppErrorReporter._();

  static const bool _enableInDebug = bool.fromEnvironment(
    'ENABLE_ERROR_REPORTING_IN_DEBUG',
    defaultValue: false,
  );

  /// Error reporting is disabled in debug builds unless explicitly enabled
  /// with --dart-define=ENABLE_ERROR_REPORTING_IN_DEBUG=true.
  static bool get isEnabled => !kDebugMode || _enableInDebug;

  static const Duration _deduplicationWindow = Duration(seconds: 45);
  static const int _maxFingerprints = 75;
  static const int _maxPendingReports = 10;

  final LinkedHashMap<String, DateTime> _fingerprints =
      LinkedHashMap<String, DateTime>();
  final List<AppErrorReportRequest> _pendingReports = <AppErrorReportRequest>[];

  Dio? _dio;
  bool _isReady = false;
  Future<void>? _initialization;
  String? _appVersion;
  String? _platform;
  String? _osVersion;
  String? _deviceModel;

  Future<void> initialize() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    if (!isEnabled) {
      _pendingReports.clear();
      logger.i('[AppErrorReporter] Reporting is disabled in debug mode.');
      return;
    }

    final baseUrl = EnvConfig.apiBaseUrl;
    if (baseUrl.isEmpty) {
      logger.w('[AppErrorReporter] API_BASE_URL is empty; reporting disabled.');
      return;
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: const <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    await Future.wait<void>(<Future<void>>[
      _loadPackageInfo(),
      _loadDeviceInfo(),
    ]);

    _isReady = true;
    final queuedReports = List<AppErrorReportRequest>.of(_pendingReports);
    _pendingReports.clear();
    for (final report in queuedReports) {
      unawaited(_send(report));
    }
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.buildNumber.isEmpty
          ? info.version
          : '${info.version}+${info.buildNumber}';
    } catch (error, stackTrace) {
      logger.w(
        '[AppErrorReporter] Could not read package info.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _loadDeviceInfo() async {
    _platform = _platformName();
    try {
      final info = await DeviceInfoPlugin().deviceInfo;
      final data = info.data;
      final version = data['version'];
      final versionData = version is Map ? version : const <String, dynamic>{};

      _osVersion = _firstNonEmpty(<Object?>[
        data['systemVersion'],
        versionData['release'],
        data['osRelease'],
        data['version'],
        data['buildNumber'],
      ]);
      _deviceModel = _firstNonEmpty(<Object?>[
        data['model'],
        data['productName'],
        data['prettyName'],
        data['computerName'],
        data['name'],
        data['browserName'],
      ]);
    } catch (error, stackTrace) {
      logger.w(
        '[AppErrorReporter] Could not read device info.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> reportApiError(DioException error) async {
    if (!isEnabled) return;

    final request = error.requestOptions;
    final response = error.response;
    final type = classifyDioError(error);
    final requestDetails = <String, dynamic>{};

    if (request.queryParameters.isNotEmpty) {
      requestDetails['query_parameters'] = AppErrorSanitizer.sanitizeMap(
        request.queryParameters,
      );
    }
    if (request.data != null) {
      requestDetails['body'] = AppErrorSanitizer.sanitize(request.data);
    }

    final sanitizedRequest = requestDetails.isEmpty
        ? null
        : AppErrorSanitizer.sanitizePayloadMap(requestDetails);
    final responseDetails = response?.data == null
        ? null
        : AppErrorSanitizer.sanitizePayloadMap(<String, dynamic>{
            'body': response?.data,
          });
    final responseCode = _extractResponseCode(response?.data);

    await reportError(
      type: type,
      severity: AppErrorSeverity.error,
      message: error.message?.trim().isNotEmpty == true
          ? error.message!
          : 'Dio request failed: ${request.method} ${request.uri.path}',
      errorCode: responseCode ?? error.type.name,
      source: 'ApiService',
      error: error,
      stackTrace: error.stackTrace,
      apiMethod: request.method,
      apiUrl: AppErrorSanitizer.sanitizeUrl(request.uri),
      apiStatusCode: response?.statusCode,
      apiRequest: sanitizedRequest,
      apiResponse: responseDetails,
    );
  }

  Future<void> reportRuntimeError(
    Object error,
    StackTrace stackTrace, {
    String source = 'UncaughtRuntimeError',
    AppErrorSeverity severity = AppErrorSeverity.fatal,
    Map<String, dynamic>? context,
  }) {
    return reportError(
      type: AppErrorType.runtime,
      severity: severity,
      message: error.toString(),
      source: source,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  Future<void> reportError({
    required AppErrorType type,
    required String message,
    AppErrorSeverity severity = AppErrorSeverity.error,
    String? customType,
    String? errorCode,
    String? source,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? apiMethod,
    String? apiUrl,
    int? apiStatusCode,
    Map<String, dynamic>? apiRequest,
    Map<String, dynamic>? apiResponse,
    DateTime? occurredAt,
  }) async {
    if (!isEnabled) return;

    try {
      final reportContext = <String, dynamic>{...?context};
      try {
        final route = Get.currentRoute;
        if (route.isNotEmpty) reportContext.putIfAbsent('screen', () => route);
      } catch (_) {
        // GetX navigation may not be initialized during application startup.
      }
      if (error != null) {
        reportContext.putIfAbsent(
          'error_class',
          () => error.runtimeType.toString(),
        );
      }

      final report = AppErrorReportRequest(
        type: type,
        severity: severity,
        message: AppErrorSanitizer.redactText(
          message.trim().isEmpty ? 'Unknown application error' : message,
          maxLength: 4000,
        ),
        customType: _sanitizeOptionalText(customType, maxLength: 100),
        errorCode: _sanitizeOptionalText(errorCode, maxLength: 200),
        source: _sanitizeOptionalText(source, maxLength: 500),
        stackTrace: stackTrace == null
            ? null
            : AppErrorSanitizer.redactText(
                stackTrace.toString(),
                maxLength: 12000,
              ),
        context: reportContext.isEmpty
            ? null
            : AppErrorSanitizer.sanitizeMap(reportContext),
        apiMethod: apiMethod,
        apiUrl: _sanitizeApiUrl(apiUrl),
        apiStatusCode: apiStatusCode,
        apiRequest: apiRequest == null
            ? null
            : AppErrorSanitizer.sanitizePayloadMap(apiRequest),
        apiResponse: apiResponse == null
            ? null
            : AppErrorSanitizer.sanitizePayloadMap(apiResponse),
        occurredAt: occurredAt ?? DateTime.now(),
      );

      await _submit(report);
    } catch (reportingError, reportingStackTrace) {
      logger.w(
        '[AppErrorReporter] Failed to prepare an error report.',
        error: reportingError,
        stackTrace: reportingStackTrace,
      );
    }
  }

  static AppErrorType classifyDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return AppErrorType.network;
      case DioExceptionType.badResponse:
        switch (error.response?.statusCode) {
          case 401:
          case 403:
            return AppErrorType.authentication;
          case 422:
            return AppErrorType.validation;
          default:
            return AppErrorType.api;
        }
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return AppErrorType.api;
    }
  }

  Future<void> _submit(AppErrorReportRequest report) async {
    if (!isEnabled) return;

    final fingerprint = _fingerprint(report);
    if (_isDuplicate(fingerprint)) return;

    if (!_isReady || _dio == null) {
      if (_pendingReports.length >= _maxPendingReports) {
        _pendingReports.removeAt(0);
      }
      _pendingReports.add(report);
      return;
    }

    await _send(report);
  }

  Future<void> _send(AppErrorReportRequest report) async {
    if (!isEnabled) return;

    try {
      final payload = report.toJson();
      if (_appVersion != null) payload['app_version'] = _appVersion;
      if (_platform != null) payload['platform'] = _platform;
      if (_osVersion != null) payload['os_version'] = _osVersion;
      if (_deviceModel != null) payload['device_model'] = _deviceModel;

      final token = StorageService.readData(key: LocalStorageKeys.token);
      await _dio!.post<void>(
        AppUrl.appErrors,
        data: payload,
        options: Options(
          headers: <String, String>{
            if (token is String && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
          extra: const <String, bool>{'skipErrorReporting': true},
        ),
      );
    } catch (error) {
      logger.w(
        '[AppErrorReporter] Error report delivery failed: '
        '${error.runtimeType}',
      );
    }
  }

  bool _isDuplicate(String fingerprint) {
    final now = DateTime.now();
    _fingerprints.removeWhere(
      (_, timestamp) => now.difference(timestamp) >= _deduplicationWindow,
    );

    final previous = _fingerprints[fingerprint];
    if (previous != null && now.difference(previous) < _deduplicationWindow) {
      return true;
    }

    while (_fingerprints.length >= _maxFingerprints) {
      _fingerprints.remove(_fingerprints.keys.first);
    }
    _fingerprints[fingerprint] = now;
    return false;
  }

  String _fingerprint(AppErrorReportRequest report) {
    return <Object?>[
      report.type.value,
      report.message,
      report.source,
      report.apiMethod?.toUpperCase(),
      report.apiUrl,
      report.apiStatusCode,
    ].join('|');
  }

  static String? _extractResponseCode(Object? data) {
    if (data is! Map) return null;
    final code = data['code'];
    return code?.toString();
  }

  static String? _firstNonEmpty(Iterable<Object?> values) {
    for (final value in values) {
      if (value == null || value is Map || value is Iterable) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static String? _sanitizeOptionalText(
    String? value, {
    required int maxLength,
  }) {
    if (value == null || value.trim().isEmpty) return null;
    return AppErrorSanitizer.redactText(value, maxLength: maxLength);
  }

  static String? _sanitizeApiUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return AppErrorSanitizer.sanitizeUrl(Uri.parse(value));
    } catch (_) {
      return AppErrorSanitizer.redactText(value, maxLength: 4000);
    }
  }

  static String _platformName() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}
