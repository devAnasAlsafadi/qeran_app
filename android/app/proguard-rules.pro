# ============================================================================
# Qeran — R8 / ProGuard keep rules for the release build.
# Philosophy: err toward MORE keeps. A missing keep is a silent runtime crash
# (ClassNotFound / reflection failure), not a build error — so it must not slip
# through. Most first-party plugins ship their own consumer rules; these are
# defensive belt-and-braces on top of that.
# ============================================================================

# ---- Global attributes (reflection, generics, annotations, crash lines) ----
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod
-keepattributes Exceptions
-keepattributes SourceFile,LineNumberTable
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations,AnnotationDefault

# ---- Language / platform primitives ----
-keepclasseswithmembernames class * { native <methods>; }
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
-keepclassmembers class * implements java.io.Serializable { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }

# ---- Flutter engine + embedding + plugins ----
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ---- Google Play core (Flutter deferred-components refs; common R8 miss) ----
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ---- Firebase (core / auth / messaging) ----
-keep class com.google.firebase.** { *; }
-keepclassmembers class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ---- Google Play services (auth / base / tasks — used by Firebase + Google Sign-In) ----
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ---- RevenueCat (purchases_flutter) + Google Play Billing ----
-keep class com.revenuecat.purchases.** { *; }
-keepclassmembers class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**
-keep class com.android.billingclient.** { *; }
-keep class com.android.vending.billing.** { *; }

# ---- kotlinx.serialization (RevenueCat serializes models via generated serializers) ----
-keepattributes RuntimeVisibleAnnotations,AnnotationDefault
-keep,includedescriptorclasses class **$$serializer { *; }
-keepclassmembers class * { *** Companion; }
-keepclasseswithmembers class * {
    kotlinx.serialization.KSerializer serializer(...);
}
-dontwarn kotlinx.serialization.**

# ---- Gson (transitive JSON reflection, if pulled in) ----
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * { @com.google.gson.annotations.SerializedName <fields>; }
-dontwarn sun.misc.**

# ---- flutter_secure_storage (AndroidX security / Keystore) ----
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**

# ---- image_picker / share_plus / connectivity_plus / device_info / package_info ----
# (These ship consumer rules; keep FileProvider + plugin entry points defensively.)
-keep class androidx.core.content.FileProvider { *; }
-keep class * extends androidx.core.content.FileProvider { *; }

# ---- OkHttp / Okio (transitive via Play services / Firebase) ----
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn org.conscrypt.**
-dontwarn javax.annotation.**

# NOTE: signalr_netcore is a PURE-DART package (no Java/Kotlin reflection),
# so it needs no keep rules — its code is AOT-compiled into libapp.so.
