import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/feed/feed.dart';
import '../../../core/feed/feed_reads.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/ui/brand_card.dart';
import '../../../core/ui/info_notice.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Everything the app has told its readers, newest first — including the
/// banners that have long since left Home. The Notices tab of [InboxScreen].
class NoticesTab extends ConsumerStatefulWidget {
  const NoticesTab({super.key});

  @override
  ConsumerState<NoticesTab> createState() => _NoticesTabState();
}

class _NoticesTabState extends ConsumerState<NoticesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(feedSeenProvider.notifier).sawNotices(ref.read(noticesProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    final notices = ref.watch(noticesProvider);
    if (notices.isEmpty) {
      return QuietNotice(text: L10n.of(context).noticesEmpty);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final notice in notices) ...[
          _NoticeTile(notice: notice),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({required this.notice});

  final Notice notice;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final locale = AppLocale.of(context);
    final link = notice.link;
    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.yMMMd().format(notice.publishedAt.toLocal()),
            style: TextStyle(fontSize: 12, color: palette.muted),
          ),
          const SizedBox(height: 4),
          Text(
            notice.title.of(locale),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: palette.text,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            notice.body.of(locale),
            style: TextStyle(fontSize: 14, height: 1.5, color: palette.text),
          ),
          if (link != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () async {
                  try {
                    await launchUrl(link, mode: LaunchMode.externalApplication);
                  } on Object catch (e) {
                    AppLogger.warn('Could not open notice link: $e');
                  }
                },
                child: Text(l.announcementOpenLink),
              ),
            ),
        ],
      ),
    );
  }
}
