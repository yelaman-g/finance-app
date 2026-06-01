import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_gradients.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// Hero balance card. Brand gradient, soft inner highlight, animated balance.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    required this.balance,
    required this.currency,
    required this.delta,
    super.key,
  });

  final double balance;
  final String currency;

  /// Percent change vs last month (e.g. 0.082 = +8.2%).
  final double delta;

  @override
  Widget build(BuildContext context) {
    final positive = delta >= 0;
    final fmt = NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: 0,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x402F6BFF),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Total balance',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _DeltaPill(value: delta, positive: positive),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: balance),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Text.rich(
                  TextSpan(
                    style: AppTypography.display.copyWith(
                      color: Colors.white,
                      fontSize: 38,
                      letterSpacing: -1,
                    ),
                    children: [
                      TextSpan(text: fmt.format(v)),
                      TextSpan(
                        text: '  $currency',
                        style: AppTypography.title.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  _MiniStat(label: 'Income', value: '+${fmt.format(820000)}'),
                  const SizedBox(width: AppSpacing.lg),
                  _MiniStat(label: 'Expense', value: '-${fmt.format(412300)}'),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04);
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({required this.value, required this.positive});
  final double value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final pct = '${(value * 100).abs().toStringAsFixed(1)}%';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.trending_up : Icons.trending_down,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            pct,
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTypography.title.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
