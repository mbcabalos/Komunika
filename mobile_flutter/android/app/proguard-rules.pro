# Keep ML Kit text recognition classes
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep TensorFlow Lite classes
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# Keep Flutter plugin classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
