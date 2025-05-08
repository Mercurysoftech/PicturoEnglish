# Keep Razorpay classes
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keepattributes *Annotation*
-keepclasseswithmembers class * {
    @com.razorpay.* <methods>;
}