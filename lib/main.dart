import 'dart:async';
import 'dart:ui';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import các file của bạn (giữ nguyên)
import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/core/utils/app_translations.dart';
import 'package:sukientotapp/core/error_reporting/app_error_log_bridge.dart';
import 'package:sukientotapp/core/error_reporting/app_error_reporter.dart';
import 'package:sukientotapp/features/common/dev_overlay/dev_overlay.dart';
import 'package:sukientotapp/core/services/api_service.dart';
import 'package:sukientotapp/core/services/call_coordinator.dart';
import 'package:sukientotapp/data/providers/common/call_provider.dart';
import 'package:sukientotapp/data/repositories/common/call_repository_impl.dart';
import 'package:sukientotapp/domain/repositories/common/call_repository.dart';
import 'package:sukientotapp/features/common/call/widgets/call_ui.dart';

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      _installGlobalErrorHandlers();

      await dotenv.load();
      await GetStorage.init();

      final errorReporter = AppErrorReporter.instance;
      await errorReporter.initialize();
      Get.put<AppErrorReporter>(errorReporter, permanent: true);
      AppErrorLogBridge.install(reporter: errorReporter);

      final apiService = Get.put<ApiService>(ApiService(), permanent: true);
      final callRepository = Get.put<CallRepository>(
        CallRepositoryImpl(CallProvider(apiService)),
        permanent: true,
      );
      Get.put<CallCoordinator>(
        CallCoordinator(callRepository),
        permanent: true,
      );

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      runApp(const GoodEvent());
      unawaited(NotificationService.init());
    },
    (error, stackTrace) {
      logger.e(
        '[GlobalErrorHandler] Unhandled asynchronous error.',
        error: error,
        stackTrace: stackTrace,
      );
      unawaited(
        AppErrorReporter.instance.reportRuntimeError(
          error,
          stackTrace,
          source: 'runZonedGuarded',
        ),
      );
    },
  );
}

void _installGlobalErrorHandlers() {
  final previousFlutterHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    if (previousFlutterHandler != null) {
      previousFlutterHandler(details);
    } else {
      FlutterError.presentError(details);
    }
    unawaited(
      AppErrorReporter.instance.reportRuntimeError(
        details.exception,
        details.stack ?? StackTrace.current,
        source: details.library ?? 'FlutterError',
      ),
    );
  };

  final previousPlatformHandler = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logger.e(
      '[GlobalErrorHandler] Unhandled platform error.',
      error: error,
      stackTrace: stackTrace,
    );
    unawaited(
      AppErrorReporter.instance.reportRuntimeError(
        error,
        stackTrace,
        source: 'PlatformDispatcher',
      ),
    );
    return previousPlatformHandler?.call(error, stackTrace) ?? true;
  };
}

class GoodEvent extends StatelessWidget {
  const GoodEvent({super.key});

  FThemeData _buildLightTheme() {
    final base = FThemes.zinc.light;
    return FThemeData(
      colors: base.colors.copyWith(
        primary: AppColors.red600,
        primaryForeground: AppColors.white,
        background: AppColors.lightBackground,
        foreground: AppColors.lightForeground,
        muted: AppColors.lightMuted,
        mutedForeground: AppColors.lightMutedForeground,
        border: AppColors.lightBorder,
        error: AppColors.error,
        destructive: AppColors.error,
        destructiveForeground: AppColors.white,
      ),
      typography: _buildTypography(base.typography),
      style: base.style,
    );
  }

  FThemeData _buildDarkTheme() {
    final base = FThemes.zinc.dark;
    return FThemeData(
      colors: base.colors.copyWith(
        primary: Colors.black,
        primaryForeground: AppColors.white,
        background: AppColors.darkBackground,
        foreground: AppColors.darkForeground,
        muted: AppColors.darkMuted,
        mutedForeground: AppColors.darkMutedForeground,
        border: AppColors.darkBorder,
        error: AppColors.error,
        destructive: AppColors.error,
        destructiveForeground: AppColors.white,
      ),
      typography: _buildTypography(base.typography),
      style: base.style,
    );
  }

  FTypography _buildTypography(FTypography base) {
    const fontFamily = 'Lexend';
    return base.copyWith(
      xs: base.xs.copyWith(fontFamily: fontFamily),
      sm: base.sm.copyWith(fontFamily: fontFamily),
      base: base.base.copyWith(fontFamily: fontFamily),
      lg: base.lg.copyWith(fontFamily: fontFamily),
      xl: base.xl.copyWith(fontFamily: fontFamily),
      xl2: base.xl2.copyWith(fontFamily: fontFamily),
      xl3: base.xl3.copyWith(fontFamily: fontFamily),
      xl4: base.xl4.copyWith(fontFamily: fontFamily),
      xl5: base.xl5.copyWith(fontFamily: fontFamily),
      xl6: base.xl6.copyWith(fontFamily: fontFamily),
      xl7: base.xl7.copyWith(fontFamily: fontFamily),
      xl8: base.xl8.copyWith(fontFamily: fontFamily),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = _buildLightTheme();
    final darkTheme = _buildDarkTheme();

    return GetMaterialApp(
      initialRoute: Pages.initialRoute,
      getPages: Pages.routes,
      debugShowCheckedModeBanner: true,
      translations: AppTranslations(),
      locale: const Locale('vi', 'VN'),
      fallbackLocale: const Locale('en', 'US'),
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
        SfGlobalLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],

      themeMode: ThemeMode.light,

      theme: ThemeData(
        fontFamily: 'Lexend',
        colorScheme: ColorScheme.light(
          primary: AppColors.red600,
          surface: AppColors.lightBackground,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.lightBackground,
      ),
      darkTheme: ThemeData(
        fontFamily: 'Lexend',
        colorScheme: ColorScheme.dark(
          primary: AppColors.red500,
          surface: AppColors.darkBackground,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
      ),

      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        final theme = brightness == Brightness.dark ? darkTheme : lightTheme;

        return FTheme(
          data: theme,
          child: CallResumeNavigator(
            child: GlobalIncomingCallOverlay(
              child: CallRecoveryBanner(
                child: DevOverlay(child: child!),
              ),
            ),
          ),
        );
      },
    );
  }
}
