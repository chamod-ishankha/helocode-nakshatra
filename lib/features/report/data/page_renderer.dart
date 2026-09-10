import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Rendering a report page off screen (KAN-37).
///
/// ## Why the pages are images and not PDF text
///
/// Sinhala and Tamil are complex scripts: what a reader sees is not one glyph
/// per codepoint. A conjunct like ශ්‍රී is produced by the font's GSUB table
/// substituting a sequence of codepoints with a single glyph, and the vowel
/// signs are placed by GPOS. Both bundled fonts carry those tables — they have
/// to, or the scripts cannot be drawn at all.
///
/// The `pdf` package's text engine maps codepoints straight through `cmap` and
/// contains no reference to GSUB or GPOS anywhere in its source. Handing it
/// Sinhala would emit each codepoint as its own base glyph, side by side: not
/// slightly off, but unreadable, and unreadable in the language most of the
/// buyers read.
///
/// Flutter shapes text with HarfBuzz. So the report is drawn by the same
/// engine that draws the app, captured, and embedded as an image. What that
/// costs is selectable text; what it buys is the acceptance criterion on this
/// ticket — if it looks right on screen it is right in the file, in all three
/// languages, with no second text stack to be wrong.
///
/// ## Why off screen rather than in the widget tree
///
/// A page is A4 and there are several of them. Mounting them in the live tree
/// to photograph them would mean a screen-sized widget scrolling past behind a
/// spinner, and it would tie report generation to a live [BuildContext]. This
/// builds its own render tree instead, so a report can be produced from a
/// service, on any screen, at a size no screen has.
abstract final class PageRenderer {
  /// A4 in PostScript points, which is also the PDF's own unit.
  ///
  /// Rendering at exactly this size means one logical pixel is one point, so
  /// the captured image drops onto the page 1:1 with no scaling arithmetic to
  /// get wrong.
  ///
  /// Rounded from A4's true 595.28 x 841.89. The fraction is not free: a page
  /// 595.28 wide captures into a 596-pixel image whose last column is 28%
  /// covered, which comes out as a thin part-transparent stripe down the right
  /// edge of every page. Two hundredths of a millimetre of paper is a fair
  /// trade for not shipping that in a paid document.
  static const Size a4 = Size(595, 842);

  /// Roughly 216 dpi. Sharp on a phone, sharp enough to print, and still a
  /// file that can be sent over WhatsApp on a Sri Lankan connection.
  static const double defaultPixelRatio = 3;

  /// Draws [page] at [size] and returns PNG bytes.
  ///
  /// PNG rather than JPEG deliberately: a chart is thin lines and flat fills,
  /// which is exactly what JPEG smears and what PNG compresses well.
  static Future<Uint8List> renderPng(
    Widget page, {
    Size size = a4,
    double pixelRatio = defaultPixelRatio,
  }) async {
    final boundary = RenderRepaintBoundary();
    final view = _view();

    final renderView = RenderView(
      view: view,
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(size),
        physicalConstraints: BoxConstraints.tight(size * pixelRatio),
        devicePixelRatio: pixelRatio,
      ),
      child: RenderPositionedBox(child: boundary),
    );

    final pipelineOwner = PipelineOwner()..rootNode = renderView;
    renderView.prepareInitialFrame();

    final buildOwner = BuildOwner(focusManager: FocusManager());
    final RenderObjectToWidgetElement<RenderBox> element =
        RenderObjectToWidgetAdapter<RenderBox>(
          container: boundary,
          child: _Frame(size: size, pixelRatio: pixelRatio, child: page),
        ).attachToRenderTree(buildOwner);

    try {
      // Three passes with a turn of the event loop between them.
      //
      // A Localizations widget resolves its delegates through futures. For
      // every locale this app supports they are SynchronousFutures and one
      // pass is enough — but a delegate that ever answers asynchronously would
      // otherwise capture the page before its text arrived, and a blank page
      // in a paid report is the kind of thing nobody notices until a customer
      // does.
      for (var pass = 0; pass < 3; pass++) {
        buildOwner
          ..buildScope(element)
          ..finalizeTree();
        pipelineOwner
          ..flushLayout()
          ..flushCompositingBits()
          ..flushPaint();

        if (pass < 2) await Future<void>.delayed(Duration.zero);
      }

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) {
          throw StateError('report page could not be encoded');
        }
        return data.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      _teardown(buildOwner, element, boundary, renderView, pipelineOwner);
    }
  }

  /// Releases the tree this page built.
  ///
  /// A report is six of these, so a leak here is six widget trees and six
  /// A4-sized layers held for the life of the process.
  ///
  /// The tree is torn down by rebuilding it with no child rather than by
  /// unmounting the element directly: an [Element] cannot be unmounted while
  /// it is still active, and [BuildOwner.finalizeTree] is the thing that
  /// unmounts what the rebuild left inactive.
  ///
  /// Failures are logged and swallowed. This runs in a `finally`, and a
  /// teardown that throws would replace a page that rendered perfectly well
  /// with an exception — losing the work to tidying up after it.
  static void _teardown(
    BuildOwner buildOwner,
    RenderObjectToWidgetElement<RenderBox> element,
    RenderRepaintBoundary boundary,
    RenderView renderView,
    PipelineOwner pipelineOwner,
  ) {
    try {
      RenderObjectToWidgetAdapter<RenderBox>(
        container: boundary,
      ).attachToRenderTree(buildOwner, element);
      buildOwner
        ..buildScope(element)
        ..finalizeTree();

      // Order matters and each step is asserted by the framework: the view
      // gives up its child, the owner gives up its root, and only then can
      // either be disposed.
      renderView.child = null;
      pipelineOwner.rootNode = null;
      renderView.dispose();
      pipelineOwner.dispose();
    } on Object catch (e, s) {
      debugPrint('Report page teardown failed: $e\n$s');
    }
  }

  static ui.FlutterView _view() {
    final dispatcher = ui.PlatformDispatcher.instance;
    return dispatcher.implicitView ?? dispatcher.views.first;
  }
}

/// The inherited widgets a page needs when nothing above it provides them.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.size,
    required this.pixelRatio,
    required this.child,
  });

  final Size size;
  final double pixelRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQueryData(
      size: size,
      devicePixelRatio: pixelRatio,
      // Fixed, and this is not a detail. Report pages are a fixed height, so
      // honouring the phone's font-size setting would push a table off the
      // bottom of a page for exactly the users who need larger text — and the
      // page is a paid product, not a screen they can scroll.
      textScaler: TextScaler.noScaling,
    ),
    // Every script this app supports reads left to right, but Directionality
    // has no default and its absence is an assertion failure rather than a
    // fallback.
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );
}
