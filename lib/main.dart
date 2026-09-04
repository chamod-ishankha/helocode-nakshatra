import 'bootstrap.dart';
import 'core/config/flavor.dart';

/// Default entrypoint, used when no `--target` is passed.
///
/// Mirrors dev so a bare `flutter run` never accidentally starts a build with
/// live ads or production analytics enabled.
Future<void> main() => bootstrap(Flavor.dev);
