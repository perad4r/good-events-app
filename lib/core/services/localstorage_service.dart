import 'package:get_storage/get_storage.dart' hide Data;

final box = GetStorage();

class StorageService {
  static dynamic readData({required String key}) {
    return box.read(key);
  }

  static bool checkData({required String key}) {
    return box.hasData(key);
  }

  static void writeStringData({required String key, required String value}) {
    box.write(key, value);
  }

  static void writeBoolData({required String key, required bool value}) {
    box.write(key, value);
  }

  static void writeMapData({
    required String key,
    required Map<String, dynamic> value,
  }) {
    box.write(key, value);
  }

  static dynamic readMapData({required String key, String mapKey = ''}) {
    final map = box.read<Map<String, dynamic>>(key);
    if (mapKey.isNotEmpty && map != null) {
      return map[mapKey];
    }
    return map;
  }

  static void removeData({required String key}) {
    box.remove(key);
  }

  static void clearAllData() {
    box.erase();
  }

  static dynamic updateMapData({
    required String key,
    required String mapKey,
    required dynamic value,
  }) {
    final map = box.read<Map<String, dynamic>>(key) ?? {};
    map[mapKey] = value;
    box.write(key, map);
    return map;
  }
}

class LocalStorageKeys {
  static const String token = "token";
  static const String isTokenExist = "isTokenExist";

  static const String user = "user";

  //Partner dashboard data
  static const String newBill = "new_bill";
  static const String waitingBill = "waiting_bill";
  static const String hasNotification = "has_notification";

  // Firebase Cloud Messaging
  static const String fcmToken = "fcm_token";

  // Pending deep link (from terminated-state notification tap)
  static const String pendingThreadId = "pending_thread_id";

  // App settings
  static const String locale = "locale";
  static const String settings = "settings";
}
