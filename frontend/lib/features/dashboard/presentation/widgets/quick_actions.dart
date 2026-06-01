import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  static const _items = <_QA>[
    _QA('Send', Icons.north_east_rounded),
    _QA('Add', Icons.add_rounded),
    _QA('Pay', Icons.qr_code_rounded),
    _QA('Top up', Icons.south_west_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final qa in _items) ...[
          Expanded(child: _ActionTile(item: qa)),
          if (qa != _items.last) const SizedBox(width: AppSpacing.md),
        ],
      ],
    );
  }
}

class _QA {
  const _QA(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.item});
  final _QA item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text('${item.label} — coming soon')),
            );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(item.icon, color: AppColors.brand600, size: 22),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(item.label, style: AppTypography.caption),
            ],
          ),
        ),
      ),
    );
  }
}
