# ===============================
# Flutter
# ===============================
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# ===============================
# AndroidX / JetBrains (safe)
# ===============================
-keep class org.jetbrains.annotations.** { *; }
-dontwarn org.jetbrains.annotations.**

# ===============================
# Gson / JSON (FCM payload safety)
# ===============================
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# ===============================
# Keep annotated members (plugin safety)
# ===============================
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}