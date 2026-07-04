class AppUrl {
  // App Settings
  static const String settings = '/settings';

  // Authentication
  static const String login = '/login';
  static const String loginGoogle = '/login/google';
  static const String loginApple = '/auth/apple';
  static const String registerClient = '/register';
  static const String registerPartner = '/register/partner';
  static const String checkToken = '/check-token';
  static const String logout = '/logout';
  static const String deleteAccount = '/account/delete';
  static const String forgot = '/forgot';
  static const String forgotSend = '/forgot/send';
  static const String forgotVerifyOtp = '/forgot/verify-otp';
  static const String forgotResetPassword = '/forgot/reset-password';

  // Verify
  static const String verifySendOtp = '/verify/send-otp';
  static const String verifyOtp = '/verify/otp';

  // Firebase Cloud Messaging
  static const String updateFcmToken = '/fcm/update-token';

  // Location APIs
  static const String locations = '/locations';
  static String wards(int provinceId) => '/locations/$provinceId/wards';

  // Partner Dashboard
  static const String partnerDashboard = '/partner/dashboard';
  static const String partnerReviews = '/partner/reviews';

  // Client Home Screen APIs
  static const String homeSummary = '/event/home';
  static const String homeBlogs = '/blog/home';
  static const String partnerCategories = '/partner-categories';
  static String partnerCategoryDetail(String slug) =>
      '/partner-categories/$slug';

  // Partner New Show
  static const String partnerBillsRealtime = '/partner/bills/realtime';
  static String partnerBillAccept(int billId) =>
      '/partner/bills/$billId/accept';

  // Partner my shows
  static String partnerBills(String status) => '/partner/bills/$status';
  static const String partnerBillsHistory = '/partner/bills/history';
  static String partnerBillMarkInJob(int billId) =>
      '/partner/bills/$billId/mark-in-job';
  static String partnerBillComplete(int billId) =>
      '/partner/bills/$billId/complete';
  static String billCancel(int billId) => '/partner/bills/$billId/cancel';
  static String partnerBillReview(int billId) =>
      '/partner/bills/$billId/review';

  // Client Booking Screen APIs
  static const String quickBookingEventList = '/quick-booking/event-list';
  static const String quickBookingSave = '/quick-booking/save';

  // Client Order Screen APIs
  static const String clientOrders = '/orders';
  static const String clientHistoryOrders = '/orders/history';
  static String clientOrder(int id) => '/orders/$id';
  static String clientOrderDetail(int id) => '/orders/$id/details';
  static const String clientAssetOrders = '/asset-orders';
  static String clientHistoryOrder(int id) => '/orders/history/$id';

  static const String choosePartner = '/orders/choose-partner';
  static const String checkVoucherDiscount = '/orders/voucher-discount';
  static const String cancelOrder = '/orders/cancel';
  static const String reportUser = '/report/user';
  static const String reportBill = '/report/bill';
  static const String submitReview = '/orders/submit-review';
  static const String validateVoucher = '/orders/validate-voucher';
  static const String removeVoucher = '/orders/remove-voucher';

  // Chat / Threads
  static const String chats = '/chat';
  static String chatMessages(String threadId) =>
      '/chat/threads/$threadId/messages';

  // Partner Services
  static const String partnerServices = '/partner/service/index';
  static const String partnerServiceCreate = '/partner/service';
  static String partnerServiceDetail(String id) => '/partner/service/$id';
  static String partnerServiceUpdate(String id) => '/partner/service/$id';
  static String partnerServiceImages(String id) =>
      '/partner/service/$id/images';
  static String partnerServiceDeleteImage(String serviceId, String mediaId) =>
      '/partner/service/$serviceId/images/$mediaId';

  // Partner Categories
  static const String partnerServiceCategories = '/partner/category/index';

  // Profile
  static const String profile = '/profile/me';
  static String publicProfile(int userId) => '/profile/$userId';
  static const String updateProfile = '/profile/update';
  static const String updatePassword = '/profile/password';

  // Partner Wallet
  static const String partnerWalletTransactions =
      '/partner/wallet/transactions';
  static const String partnerWalletRegenerateAddFundsLink =
      '/partner/wallet/regenerate-add-funds-link';
  static const String partnerWalletConfirmAddFunds =
      '/partner/wallet/confirm-add-funds';

  // Partner Service Areas
  static const String partnerServiceAreas = '/partner/service-areas';
  static const String partnerServiceAreasUpdate =
      '/partner/service-areas/update';

  // Partner Analytics
  static const String partnerAnalyticsStatistics =
      '/partner/analytics/statistics';
  static const String partnerAnalyticsRevenueChart =
      '/partner/analytics/revenue-chart';
  static const String partnerAnalyticsTopServices =
      '/partner/analytics/top-services';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';
}
