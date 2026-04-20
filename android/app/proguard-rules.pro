-dontwarn org.conscrypt.**
-dontwarn javax.annotation.**
-dontwarn sun.misc.**

-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.util.PathUtils { *; }

-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.datatransport.** { *; }

-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}
