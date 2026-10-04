# vosk_flutter uses JNA to call into the native Vosk library.
-keep class com.sun.jna.* { *; }
-keepclassmembers class * extends com.sun.jna.* { public *; }

# JNA's cross-platform code references desktop-only java.awt.* classes (for
# window-handle lookups on desktop JVMs) that don't exist on Android and are
# never actually reached there — R8 fails hard on the missing classes unless
# told to ignore them (plain warnings, not real problems).
-dontwarn java.awt.**
