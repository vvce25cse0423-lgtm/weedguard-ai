# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Kotlin
-dontwarn kotlin.**
-dontwarn kotlin.reflect.**
-keepattributes *Annotation*, InnerClasses, EnclosingMethod, Signature

# Supabase / GoTrue / Postgrest / Realtime
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Geolocator / Permissions
-dontwarn com.baseflow.permissionhandler.**
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.geolocator.**
-keep class com.baseflow.geolocator.** { *; }

# Text to Speech
-keep class com.tundralabs.fluttertts.** { *; }
-dontwarn com.tundralabs.fluttertts.**

# Printing / PDF
-dontwarn net.nfet.flutter.printing.**
-keep class net.nfet.flutter.printing.** { *; }

# Desugaring / Java 8+ APIs
-dontwarn java.lang.invoke.**
-dontwarn javax.annotation.**

# WeedGuard Data Models
-keep class com.weedguard.app.** { *; }
