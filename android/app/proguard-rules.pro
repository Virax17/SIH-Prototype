# vosk_flutter uses JNA to call into the native Vosk library.
-keep class com.sun.jna.* { *; }
-keepclassmembers class * extends com.sun.jna.* { public *; }
