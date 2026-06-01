import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../models/dashboard_mock.dart';

class RecentTransactions extends StatelessWidget {
  const RecentTransactions({required this.items, super.key});
  final List<TxItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: AppSpacing.xl + 44,
          endIndent: AppSpacing.xl,
        ),
        itemBuilder: (_, i) => _TxRow(item: items[i]),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.item});
  final TxItem item;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: 0,
    );
    final amount = (item.isIncome ? '+' : '-') + fmt.format(item.amount.abs());
    final amountColor =
        item.isIncome ? AppColors.success : AppColors.graphite900;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.title.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(item.subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          Text(
            '$amount ₸',
            style: AppTypography.title.copyWith(
              color: amountColor,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
