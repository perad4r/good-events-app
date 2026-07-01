part of 'pages.dart';

abstract class Routes {
  Routes._();

  static const splashScreen = '/splash';
  static const chooseYoSideScreen = '/choose-yo-side';
  static const guestHomeScreen = '/guest/home';
  static const loginScreen = '/login';
  static const registerScreen = '/register';
  static const userVerifyScreen = '/verify';
  static const introduction = '/introduction';
  static const notification = '/notification';

  //Required Auth
  //Common
  static const myProfile = '/my-profile';
  static const editProfile = '/my-profile/edit';
  static const changePassword = '/change-password';

  // Partner
  static const partnerHome = '/partner/home';
  static const partnerShowCalendar = '/partner/show-calendar';
  static const partnerMyServices = '/partner/my-services';
  static const partnerServiceAreas = '/partner/service-areas';
  static const partnerAnalytics = '/partner/analytics';

  // Client
  static const clientHome = '/client/home';
  static const partnerDetail = '/client/partner-detail';
  static const clientBooking = '/client/client-booking';
  static const clientOrderDetail = '/client/order-detail';
  static const clientAssetOrderDetail = '/client/asset-order-detail';
  static const webView = '/webview';
  static const paymentResult = '/payment-result';
  static const forgotPasswordScreen = '/forgot-password';
}
