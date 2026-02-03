# ===============================
# Flutter
# ===============================
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# ===============================
# Flutter Local Notifications
# ===============================
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# ===============================
# AndroidX / JetBrains (safe)
# ===============================
-keep class org.jetbrains.annotations.** { *; }
-dontwarn org.jetbrains.annotations.**

# ===============================
# Timezone (tz)
# ===============================
-keep class com.github.cderrah.timezone.** { *; }
-dontwarn com.github.cderrah.timezone.**

# ===============================
# Gson / JSON (payload decode safety)
# ===============================
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# ===============================
# Reflection safety (used internally by plugins)
# ===============================
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}