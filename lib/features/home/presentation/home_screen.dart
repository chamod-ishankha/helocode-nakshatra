import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/flavor.dart';
import '../../../core/theme/app_theme.dart';

/// Placeholder home screen.
///
/// Replaced by the real daily dashboard in KAN-27. It exists now only so the
/// router, theme and flavor wiring can be verified end to end.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = FlavorConfig.current;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(config.appName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('නැකත්', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('நட்சத்திரம்', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Nakshatra', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 32),
              _StatusChip(
                label: 'Flavor',
                value: config.flavor.name,
                color: config.flavor.isProd
                    ? AppColors.auspicious
                    : AppColors.accent,
              ),
              const SizedBox(height: 8),
              _StatusChip(
                label: 'Ads',
                value: config.enableAds ? 'enabled' : 'disabled',
                color: config.enableAds
                    ? AppColors.inauspicious
                    : AppColors.auspicious,
              ),
              const SizedBox(height: 24),
              Text(
                'Scaffold only. Daily horoscope and nekath land in KAN-27.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}
