# ProGuard rules for Razorpay SDK
# Required for release builds to prevent obfuscation issues

-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

-keepattributes JavascriptInterface
-keepattributes *Annotation*

# Keep Razorpay classes
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}

# Keep payment callback methods
-keepclasseswithmembers class * {
  public void onPayment*(...);
}

# Optimization settings
-optimizations !method/inlining/*

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
