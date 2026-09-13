-optimizationpasses 5
-allowaccessmodification
-repackageclasses 'dsns'
-flattenpackagehierarchy

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

-keep class com.aheaditec.** { *; }
-dontwarn com.aheaditec.**

-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

-keep class com.google.crypto.tink.** { *; }
-keep class androidx.credentials.** { *; }

-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
