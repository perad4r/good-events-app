# Tránh lỗi thiếu Google Play Core (Deferred Components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Tránh lỗi SLF4J (Thường đi kèm với các thư viện log/backend)
-dontwarn org.slf4j.**
-keep class org.slf4j.** { *; }

# Các rule quan trọng cho Flutter bản mới
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Fix: PlatformException channel-error cho path_provider_android (Pigeon)
# R8/ProGuard xóa các Pigeon-generated class trong release mode
-keep class dev.flutter.pigeon.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# Giữ tất cả Flutter plugin channels khỏi bị obfuscate
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# ── Pusher Channels ──────────────────────────────────────────────────────────
# pusher_channels_flutter dùng JNI/reflection để gọi PusherAndroid SDK
-keep class com.pusher.** { *; }
-keep interface com.pusher.** { *; }
-dontwarn com.pusher.**
-keep class com.github.pusher.** { *; }
-dontwarn com.github.pusher.**

# ── OkHttp / Okio (dùng bởi Dio trên Android) ───────────────────────────────
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class okio.** { *; }
-dontwarn okio.**

# ── Dio ──────────────────────────────────────────────────────────────────────
-keep class io.github.azhon.** { *; }
-dontwarn io.github.azhon.**

# ── GetStorage ───────────────────────────────────────────────────────────────
-keep class com.getkeepsafe.relinker.** { *; }
-dontwarn com.getkeepsafe.relinker.**

# ── Sqflite ──────────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.sqflite.** { *; }
-dontwarn io.flutter.plugins.sqflite.**

# ── Firebase Messaging ───────────────────────────────────────────────────────
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# ── Nếu vẫn báo thiếu class, bật dòng này để debug ─────────────────────────
-ignorewarnings
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
