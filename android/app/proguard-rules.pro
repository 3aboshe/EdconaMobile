# ==============================================================================
# EdCona ProGuard/R8 Rules
# ==============================================================================
# These rules prevent R8 from stripping classes needed at runtime.
# Required for AAB builds submitted to Google Play Store.
# ==============================================================================

# ------------------------------------------------------------------------------
# Flutter Engine & Plugins
# ------------------------------------------------------------------------------
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ------------------------------------------------------------------------------
# Flutter Secure Storage
# Uses JNI and native code that R8 cannot detect
# ------------------------------------------------------------------------------
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# Keep Android Keystore classes
-keep class android.security.keystore.** { *; }
-dontwarn android.security.keystore.**

# ------------------------------------------------------------------------------
# PointyCastle & Encrypt (Cryptography)
# These use reflection for algorithm lookup
# ------------------------------------------------------------------------------
-keep class org.bouncycastle.** { *; }
-keep class org.spongycastle.** { *; }
-dontwarn org.bouncycastle.**
-dontwarn org.spongycastle.**

# Keep all crypto-related classes
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }

# ------------------------------------------------------------------------------
# Dio HTTP Client
# Uses interceptors and type adapters via reflection
# ------------------------------------------------------------------------------
-keep class dio.** { *; }
-dontwarn dio.**

# OkHttp (underlying HTTP client)
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ------------------------------------------------------------------------------
# JSON Serialization (used by easy_localization and Dio)
# ------------------------------------------------------------------------------
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Gson
-keep class com.google.gson.** { *; }
-keep class com.google.gson.stream.** { *; }

# Keep model classes (prevent field name obfuscation)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ------------------------------------------------------------------------------
# Kotlin Support
# ------------------------------------------------------------------------------
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keepattributes RuntimeVisibleAnnotations
-keepattributes KotlinMetadata

-dontwarn kotlin.**
-dontwarn kotlinx.**

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}

# ------------------------------------------------------------------------------
# Native Methods
# Prevent stripping of JNI bindings
# ------------------------------------------------------------------------------
-keepclasseswithmembernames class * {
    native <methods>;
}

# ------------------------------------------------------------------------------
# Android Components
# ------------------------------------------------------------------------------
# Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Views with onClick handlers
-keepclassmembers class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# ------------------------------------------------------------------------------
# URL Launcher Plugin
# ------------------------------------------------------------------------------
-keep class io.flutter.plugins.urllauncher.** { *; }

# ------------------------------------------------------------------------------
# Image Picker & File Picker Plugins
# ------------------------------------------------------------------------------
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# ------------------------------------------------------------------------------
# SharedPreferences Plugin
# ------------------------------------------------------------------------------
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ------------------------------------------------------------------------------
# Debugging: Keep source file and line numbers for crash reports
# ------------------------------------------------------------------------------
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ==============================================================================
# END OF PROGUARD RULES
# ==============================================================================
