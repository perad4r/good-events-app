import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:sukientotapp/core/error_reporting/app_error_log_bridge.dart';
import 'package:sukientotapp/core/error_reporting/app_error_report_request.dart';
import 'package:sukientotapp/core/error_reporting/app_error_reporter.dart';
import 'package:sukientotapp/core/error_reporting/app_error_sanitizer.dart';
import 'package:sukientotapp/core/error_reporting/app_error_types.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/main.dart' show GoodEvent;

void main() {
  test('error reporting is disabled by default in debug builds', () {
    expect(kDebugMode, isTrue);
    expect(AppErrorReporter.isEnabled, isFalse);
  });

  group('AppErrorReportRequest', () {
    test('normalizes API method and omits null values', () {
      final report = AppErrorReportRequest(
        type: AppErrorType.api,
        message: 'Request failed',
        apiMethod: 'get',
        apiUrl: 'https://example.com/api/orders',
        occurredAt: DateTime.utc(2026, 7, 30, 8, 30),
      );

      final json = report.toJson();

      expect(json['api_method'], 'GET');
      final localOccurredAt = DateTime.utc(2026, 7, 30, 8, 30).toLocal();
      expect(
        json['occurred_at'],
        startsWith(localOccurredAt.toIso8601String()),
      );
      expect(json['occurred_at'], matches(RegExp(r'[+-]\d{2}:\d{2}$')));
      expect(json.containsKey('stack_trace'), isFalse);
    });

    test('requires custom type for other reports', () {
      final report = AppErrorReportRequest(
        type: AppErrorType.other,
        message: 'Unknown failure',
        occurredAt: DateTime.now(),
      );

      expect(report.toJson, throwsStateError);
    });
  });

  group('AppErrorSanitizer', () {
    test('redacts nested credentials and omits binary content', () {
      final sanitized = AppErrorSanitizer.sanitizeMap(<String, dynamic>{
        'email': 'user@example.com',
        'password': 'plain-text',
        'nested': <String, dynamic>{
          'access_token': 'secret-token',
          'image': Uint8List.fromList(<int>[1, 2, 3]),
        },
      });

      expect(sanitized['email'], 'user@example.com');
      expect(sanitized['password'], AppErrorSanitizer.redactedValue);
      expect(
        (sanitized['nested'] as Map<String, dynamic>)['access_token'],
        AppErrorSanitizer.redactedValue,
      );
      expect(
        (sanitized['nested'] as Map<String, dynamic>)['image'],
        AppErrorSanitizer.omittedBinaryValue,
      );
    });

    test('redacts sensitive URL query parameters', () {
      final url = AppErrorSanitizer.sanitizeUrl(
        Uri.parse(
          'https://example.com/api/orders?page=1&access_token=top-secret',
        ),
      );

      expect(url, contains('page=1'));
      expect(url, isNot(contains('top-secret')));
    });
  });

  group('Dio error classification', () {
    test('classifies connection errors as network errors', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/orders'),
        type: DioExceptionType.connectionError,
      );

      expect(AppErrorReporter.classifyDioError(error), AppErrorType.network);
    });

    test('classifies HTTP 422 as validation', () {
      final options = RequestOptions(path: '/orders');
      final error = DioException.badResponse(
        statusCode: 422,
        requestOptions: options,
        response: Response<void>(requestOptions: options, statusCode: 422),
      );

      expect(AppErrorReporter.classifyDioError(error), AppErrorType.validation);
    });
  });

  group('AppErrorLogBridge', () {
    test('reports caught runtime errors logged with error metadata', () {
      final event = LogEvent(
        Level.error,
        'Failed to load new bills',
        error: const FormatException('Invalid numeric type'),
        stackTrace: StackTrace.current,
      );

      expect(AppErrorLogBridge.shouldReport(event), isTrue);
    });

    test('does not duplicate Dio errors handled by the interceptor', () {
      final event = LogEvent(
        Level.error,
        'Request failed',
        error: DioException(
          requestOptions: RequestOptions(path: '/orders'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(AppErrorLogBridge.shouldReport(event), isFalse);
    });

    test('ignores legacy Dio logs that pass only the message', () {
      final event = LogEvent(
        Level.error,
        '[Provider] DioException: connection failed',
        error: 'connection failed',
      );

      expect(AppErrorLogBridge.shouldReport(event), isFalse);
    });

    test('ignores plain error strings without the original error object', () {
      final event = LogEvent(Level.error, 'An error-looking message');

      expect(AppErrorLogBridge.shouldReport(event), isFalse);
    });
  });

  test('application integration types compile', () {
    expect(GoodEvent.new, isA<Function>());
    expect(ApiService.new, isA<Function>());
  });
}
