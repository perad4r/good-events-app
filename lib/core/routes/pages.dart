import 'package:sukientotapp/core/utils/import/global.dart';
import 'package:sukientotapp/core/utils/import/screens.dart';
import 'package:sukientotapp/core/utils/import/binding.dart';

part 'routes.dart';

class Pages {
  Pages._();

  static const initialRoute = Routes.splashScreen;

  static final routes = [
    GetPage(
      name: Routes.splashScreen,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),

    GetPage(
      name: Routes.chooseYoSideScreen,
      page: () => const ChooseYoSideScreen(),
      binding: ChooseYoSideBinding(),
    ),

    GetPage(
      name: Routes.introduction,
      page: () => const IntroductionScreen(),
      binding: IntroductionBinding(),
    ),

    GetPage(
      name: Routes.loginScreen,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),

    GetPage(
      name: Routes.registerScreen,
      page: () => const RegisterScreen(),
      binding: RegisterBinding(),
    ),

    GetPage(
      name: Routes.userVerifyScreen,
      page: () => const UserVerifyScreen(),
      binding: UserVerifyBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: Routes.notification,
      page: () => const NotificationScreen(),
      binding: NotificationBinding(),
    ),

    GetPage(
      name: Routes.myProfile,
      page: () => const MyProfileScreen(),
      binding: MyProfileBinding(),
    ),

    GetPage(
      name: Routes.editProfile,
      page: () => const EditProfileScreen(),
      binding: EditProfileBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: Routes.changePassword,
      page: () => const ChangePasswordScreen(),
      binding: ChangePasswordBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: Routes.forgotPasswordScreen,
      page: () => const ForgotPasswordScreen(),
      binding: ForgotPasswordBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    //Guest
    GetPage(
      name: Routes.guestHomeScreen,
      page: () => const GuestHomeScreen(),
      binding: GuestHomeBinding(),
    ),

    //Partner
    GetPage(
      name: Routes.partnerHome,
      page: () => const PartnerBottomNavigationView(),
      binding: PartnerBottomNavigationBinding(),
    ),

    //Client
    GetPage(
      name: Routes.clientHome,
      page: () => const ClientBottomNavigationView(),
      binding: ClientBottomNavigationBinding(),
    ),

    GetPage(
      name: Routes.partnerShowCalendar,
      page: () => const ShowCalendarScreen(),
      binding: ShowCalendarBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: Routes.partnerMyServices,
      page: () => const MyServicesScreen(),
      binding: MyServicesBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: Routes.partnerServiceAreas,
      page: () => const PartnerServiceAreasScreen(),
      binding: PartnerServiceAreasBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: Routes.partnerAnalytics,
      page: () => const AnalyticsScreen(),
      binding: AnalyticsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    //Partner Detail
    GetPage(
      name: Routes.partnerDetail,
      page: () => const PartnerDetailScreen(),
      binding: PartnerDetailBinding(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    ),

    GetPage(
      name: Routes.clientBooking,
      page: () => const ClientBooking(),
      binding: ClientBookingBinding(),
    ),

    GetPage(
      name: Routes.clientOrderDetail,
      page: () => const ClientOrderDetailScreen(),
      binding: ClientOrderDetailBinding(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    ),

    GetPage(
      name: Routes.clientAssetOrderDetail,
      page: () => const ClientAssetOrderDetailScreen(),
      binding: ClientAssetOrderDetailBinding(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    ),

    GetPage(
      name: Routes.webView,
      page: () => CommonWebviewScreen(
        url: Get.arguments['url'] ?? '',
        title: Get.arguments['title'],
        allowReload: Get.arguments['allowReload'] ?? false,
        extraAllowedHosts:
            (Get.arguments['extraAllowedHosts'] as List<dynamic>?)
                ?.map((host) => host.toString())
                .toList() ??
            const [],
      ),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: Routes.paymentResult,
      page: () => const PaymentResultScreen(),
      binding: PaymentResultBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 350),
    ),
  ];
}
