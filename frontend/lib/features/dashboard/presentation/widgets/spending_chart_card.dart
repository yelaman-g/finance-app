import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// График трат по месяцам. [monthly] — суммы расходов помесячно.
class SpendingChartCard extends StatelessWidget {
  const SpendingChartCard({
    required this.monthly,
    required this.totalThisMonth,
    super.key,
  });

  final List<double> monthly;
  final double totalThisMonth;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern();
    final values = monthly.isEmpty ? <double>[0, 0] : monthly;
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
          Text('Spending', style: AppTypography.title),
          const SizedBox(height: 2),
          Text('${fmt.format(totalThisMonth)} ₸ this month',
              style: AppTypography.caption,),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 160,
            child: LineChart(
              _chartData(values),
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
                  ),)
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
