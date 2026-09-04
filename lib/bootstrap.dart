import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/flavor.dart';
import 'core/logging/app_logger.dart';

/// Shared startup path for every flavor.
///
/// Each flavor entrypoint (`main_dev.dart`, `main_staging.dart`,
/// `main_prod.dart`) calls this with its own [Flavor]. Keeping one bootstrap
/// means flavors cannot drift apart in initialisation order.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlavorConfig.initialize(flavor);
  AppLogger.initialize();
  AppLogger.info('Starting Nakshatra (${flavor.name})');

  runApp(const ProviderScope(child: NakshatraApp()));
}
