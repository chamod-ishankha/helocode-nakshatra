# Flutter's Gradle plugin supplies the core Flutter/Dart keep rules, so this
# file only needs project-specific additions.

# Swiss Ephemeris (KAN-15) will reach Dart through FFI/JNI. Native bindings are
# invoked reflectively and R8 cannot see those call sites, so add keep rules
# here when that package lands, or release builds will fail at runtime while
# debug builds pass.

# Keep annotation attributes used by reflective lookups.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
