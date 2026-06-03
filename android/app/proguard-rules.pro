# Stripe push provisioning classes (not used in Flutter, but referenced by React Native bridge)
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.**

# Flutter Secure Storage
-keepclassmembers class * implements javax.crypto.SecretKey {
    public final byte[] getEncoded();
}
