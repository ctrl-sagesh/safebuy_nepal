# SafeBuy Nepal release shrinking rules (R8).
# Flutter's gradle plugin already keeps the engine and plugin registrants;
# these rules cover libraries that use reflection.

# Firebase / Google Play services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ML Kit barcode scanning (mobile_scanner)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep model classes used by Firestore serialization
-keepattributes Signature
-keepattributes *Annotation*

# uCrop (image_cropper)
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# OkHttp/Okio (transitive)
-dontwarn okhttp3.**
-dontwarn okio.**

# Google Play Core: Flutter references deferred-components classes that are
# not bundled in a plain APK build; safe to ignore.
-dontwarn com.google.android.play.core.**
