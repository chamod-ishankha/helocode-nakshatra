import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/error/result.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/report_content.dart';
import '../presentation/report_pages.dart';
import 'page_renderer.dart';

/// Assembling the report into a PDF file (KAN-37).
///
/// Each page is drawn by Flutter, captured, and dropped onto a PDF page at 1:1
/// — see [PageRenderer] for why the pages are images and not PDF text. What is
/// left for this class is the container: page geometry, document metadata, and
/// handing the finished file to the platform.
abstract final class ReportPdf {
  /// The page box, in points, matching what [PageRenderer] draws.
  static final PdfPageFormat pageFormat = PdfPageFormat(
    PageRenderer.a4.width,
    PageRenderer.a4.height,
  );

  /// Builds the whole document.
  ///
  /// [onProgress] reports pages finished out of the total, because this takes
  /// a few seconds on a cheap phone and a spinner with no numbers on it reads
  /// as a hang.
  static Future<Uint8List> build(
    ReportContent content, {
    void Function(int done, int total)? onProgress,
    // Lowered by tests. Six A4 pages at 216 dpi is real rasterising work, and
    // a suite that pays it for every case is a suite that stops being run.
    double pixelRatio = PageRenderer.defaultPixelRatio,
    // Only the sample exporter passes this. See ReportPages.build.
    ThemeData? theme,
  }) async {
    final document = pw.Document(
      title: 'Nakshatra — ${content.profile.name}',
      author: 'HeloCode Labs',
      creator: 'Nakshatra',
      // Deliberately not the birth details. A PDF's metadata travels with the
      // file and is read by every indexer that touches it; the report is the
      // user's to share, its metadata is not something they chose to publish.
      subject: 'Birth chart report',
    );

    final total = ReportPages.count(content);
    for (var index = 0; index < total; index++) {
      final png = await PageRenderer.renderPng(
        ReportPages.build(content, index, theme: theme),
        pixelRatio: pixelRatio,
      );

      final image = pw.MemoryImage(png);
      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          // Zero, because the page image already contains its own margins.
          // The default page margin would inset the image and leave a white
          // border around a page that already had one.
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
        ),
      );

      onProgress?.call(index + 1, total);
    }

    return document.save();
  }

  /// Builds the report and opens the share sheet.
  ///
  /// Written to the temporary directory rather than kept. KAN-37 makes
  /// regeneration free after purchase precisely so a lost file is never a
  /// support question — which means there is nothing to gain from holding onto
  /// one, and a stored copy would go stale the day the user corrects a birth
  /// time.
  ///
  /// Returns a failure rather than throwing: a report that could not be built
  /// is one line on screen, not a crash on a chart the user was reading.
  static Future<Result<File>> shareReport(
    ReportContent content, {
    required String shareText,
    void Function(int done, int total)? onProgress,
  }) async {
    try {
      final bytes = await build(content, onProgress: onProgress);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${content.fileStem}.pdf');
      await file.writeAsBytes(bytes, flush: true);

      AppLogger.info(
        'Report ready: ${(bytes.length / 1024).round()} KB, '
        '${ReportPages.count(content)} pages',
      );

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: shareText),
      );
      return Result.success(file);
    } on Object catch (e, s) {
      AppLogger.error('Report generation failed', e, s);
      return Result.failure(
        UnexpectedFailure('report generation failed', cause: e),
      );
    }
  }
}
