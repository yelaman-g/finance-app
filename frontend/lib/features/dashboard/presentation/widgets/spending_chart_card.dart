import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

class SpendingChartCard extends StatefulWidget {
  const SpendingChartCard({super.key});

  @override
  State<SpendingChartCard> createState() => _SpendingChartCardState();
}

class _SpendingChartCardState extends State<SpendingChartCard> {
  static const _ranges = ['1W', '1M', '3M', '1Y'];
  int _selected = 1;

  // TODO(domain): replace with analytics use case output.
  static const _series = <List<double>>[
    [12, 18, 15, 24, 19, 27, 22],
    [80, 95, 110, 92, 130, 118, 140, 122, 155, 160, 148, 172],
    [220, 260, 300, 280, 340, 360, 330, 410, 420, 390, 450, 480],
    [900, 1100, 1050, 1200, 1180, 1320, 1400, 1380, 1510, 1620, 1580, 1700],
  ];

  @override
  Widget build(BuildContext context) {
    final data = _series[_selected];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spending', style: AppTypography.title),
                    const SizedBox(height: 2),
                    Text(
                      '412,300 ₸ this month',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              _RangeSwitcher(
                ranges: _ranges,
                selected: _selected,
                onChanged: (i) => setState(() => _selected = i),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 160,
            child: LineChart(
              _chartData(data),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.03);
  }

  LineChartData _chartData(List<double> values) {
    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.graphite900,
          tooltipRoundedRadius: 10,
          getTooltipItems: (spots) => spots
              .map((s) => LineTooltipItem(
                    s.y.toStringAsFixed(0),
                    AppTypography.caption.copyWith(color: Colors.white),
                  ))
              .toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          barWidth: 3,
          color: AppColors.brand500,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.brand500.withValues(alpha: 0.28),
                AppColors.brand500.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RangeSwitcher extends StatelessWidget {
  const _RangeSwitcher({
    required this.ranges,
    required this.selected,
    required this.onChanged,
  });
  final List<String> ranges;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < ranges.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: i == selected ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: i == selected
                      ? const [
                          BoxShadow(
                            color: AppColors.shadowSoft,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  ranges[i],
                  style: AppTypography.caption.copyWith(
                    color: i == selected
                        ? AppColors.graphite900
                        : AppColors.graphite500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
