import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error/result.dart';
import '../../../core/logging/app_logger.dart';

/// Rendering the chart to an image and handing it to the platform (KAN-53).
///
/// A shared chart travels without the app around it, so whatever is captured
/// has to stand on its own — the caption and attribution are part of the
/// boundary rather than added afterwards.
abstract final class ChartSharing {
  /// Captured at 3× so the image survives being viewed full-screen or
  /// forwarded through a messaging app that re-encodes it.
  static const double _pixelRatio = 3;

  /// Renders the widget under [boundaryKey] and opens the share sheet.
  ///
  /// Returns a failure rather than throwing: sharing is a convenience, and a
  /// codec or storage problem should surface as one line to the user, not as
  /// a crash on a screen they were only reading.
  static Future<Result<void>> shareBoundary(
    GlobalKey boundaryKey, {
    required String fileStem,
    String? text,
  }) async {
    final png = await captureBoundary(boundaryKey);
    if (png case FailureResult(:final failure)) {
      return Result.failure(failure);
    }

    try {
      // The temporary directory, not documents: this is a hand-off to another
      // app, not something the user asked us to keep.
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileStem.png');
      await file.writeAsBytes((png as Success<Uint8List>).value, flush: true);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: text),
      );
      return const Result.success(null);
    } on Object catch (e, s) {
      AppLogger.warn('Chart share failed', e, s);
      return Result.failure(
        UnexpectedFailure('chart share failed', cause: e),
      );
    }
  }

  /// Renders the boundary to PNG bytes.
  ///
  /// Split out from [shareBoundary] so the part that can actually be wrong —
  /// finding the boundary, rasterising it, encoding it — is testable. The
  /// share sheet itself is a system UI that a test cannot assert against.
  static Future<Result<Uint8List>> captureBoundary(
    GlobalKey boundaryKey,
  ) async {
    try {
      final object = boundaryKey.currentContext?.findRenderObject();
      if (object is! RenderRepaintBoundary) {
        return const Result.failure(
          UnexpectedFailure('chart boundary is not mounted'),
        );
      }

      final image = await object.toImage(pixelRatio: _pixelRatio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (bytes == null) {
        return const Result.failure(
          UnexpectedFailure('chart image could not be encoded'),
        );
      }
      return Result.success(bytes.buffer.asUint8List());
    } on Object catch (e, s) {
      AppLogger.warn('Chart capture failed', e, s);
      return Result.failure(
        UnexpectedFailure('chart capture failed', cause: e),
      );
    }
  }
}

/// Wraps what gets captured.
///
/// Everything inside is what leaves the phone, which is why the caption and
/// attribution live in here and are visible on screen too — what you see is
/// what you share, rather than an image with extra text bolted on at capture
/// time that the user never saw.
class ShareableChart extends StatelessWidget {
  const ShareableChart({
    super.key,
    required this.boundaryKey,
    required this.caption,
    required this.child,
  });

  final GlobalKey boundaryKey;
  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RepaintBoundary(
      key: boundaryKey,
      child: ColoredBox(
        // Painted explicitly: a RepaintBoundary captures transparency as
        // black, so a shared chart on a dark theme would otherwise be
        // unreadable in a light chat window.
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              child,
              const SizedBox(height: 8),
              Text(
                caption,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                // Brand, deliberately not localised.
                'Nakshatra · HeloCode Labs',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
