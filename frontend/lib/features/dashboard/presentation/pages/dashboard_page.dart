import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/shared/widgets/inset_section.dart';
import 'package:aifb/shared/widgets/large_title_scaffold.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/domain/scope.dart';
import '../../../../core/utils/hex_color.dart';
import '../../../goals/presentation/providers/goals_providers.dart';
import '../../../statistics/data/models/statistics_models.dart';
import '../../../statistics/presentation/providers/statistics_providers.dart';
import '../../../transactions/presentation/providers/finance_providers.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Scope _scope = Scope.personal;

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);

    final summary = ref.watch(summaryProvider(_scope));
    final trend = ref.watch(trendProvider(_scope));
    final txs = ref.watch(transactionsProvider(_scope));
    final goals = ref.watch(goalsProvider(_scope));

    final slivers = <Widget>[
      // ── Scope selector ────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SegmentedButton<Scope>(
          segments: const [
            ButtonSegment(value: Scope.personal, label: Text('Личное')),
            ButtonSegment(value: Scope.family, label: Text('Семья')),
          ],
          selected: {_scope},
          onSelectionChanged: (s) => setState(() => _scope = s.first),
        ),
      ),

      const SizedBox(height: 12),

      // ── Flat balance card ─────────────────────────────────────────
      summary.when(
        loading: () => _BalanceCardShell(hig: hig, child: const _LoadingIndicator()),
        error: (e, _) => _BalanceCardShell(
          hig: hig,
          child: Text('Ошибка: $e', style: TextStyle(color: hig.danger)),
        ),
        data: (s) => _FlatBalanceCard(
          hig: hig,
          net: s.net,
          income: s.income,
          expense: s.expense,
        ),
      ),

      const SizedBox(height: 16),

      // ── Spending trend chart ───────────────────────────────────────
      trend.when(
        loading: () => _ChartShell(hig: hig, child: const _LoadingIndicator()),
        error: (e, _) => _ChartShell(
          hig: hig,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Тренд расходов',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: hig.label,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.error_outline, color: hig.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Не удалось загрузить данные',
                      style: TextStyle(color: hig.danger, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        data: (points) => _FlatChartCard(
          hig: hig,
          points: points,
        ),
      ),

      const SizedBox(height: 16),

      // ── Goals ──────────────────────────────────────────────────────
      goals.when(
        loading: () => InsetSection(
          header: 'Цели',
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: _LoadingIndicator(),
            ),
          ],
        ),
        error: (e, _) => InsetSection(
          header: 'Цели',
          children: [
            InsetTile(
              title: 'Ошибка загрузки',
              subtitle: '$e',
              leading: Icon(Icons.error_outline, color: hig.danger),
            ),
          ],
        ),
        data: (list) => list.isEmpty
            ? InsetSection(
                header: 'Цели',
                children: [
                  InsetTile(
                    title: 'Целей пока нет',
                    leading: Icon(Icons.flag_outlined, color: hig.secondaryLabel),
                  ),
                ],
              )
            : InsetSection(
                header: 'Цели',
                children: [
                  for (final g in list.take(3))
                    _GoalTile(
                      hig: hig,
                      title: g.name,
                      current: g.savedAmount,
                      target: g.targetAmount,
                      color: g.color != null ? hexToColor(g.color!) : hig.accent,
                    ),
                ],
              ),
      ),

      const SizedBox(height: 16),

      // ── Recent transactions ────────────────────────────────────────
      txs.when(
        loading: () => InsetSection(
          header: 'Недавние операции',
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: _LoadingIndicator(),
            ),
          ],
        ),
        error: (e, _) => InsetSection(
          header: 'Недавние операции',
          children: [
            InsetTile(
              title: 'Ошибка загрузки',
              subtitle: '$e',
              leading: Icon(Icons.error_outline, color: hig.danger),
            ),
          ],
        ),
        data: (page) {
          final items = page.items.take(5).toList();
          if (items.isEmpty) {
            return InsetSection(
              header: 'Недавние операции',
              children: [
                InsetTile(
                  title: 'Операций пока нет',
                  leading: Icon(Icons.receipt_long_outlined, color: hig.secondaryLabel),
                ),
              ],
            );
          }
          return InsetSection(
            header: 'Недавние операции',
            children: [
              for (final t in items)
                InsetTile(
                  title: t.categoryName ?? '—',
                  subtitle: '${t.occurredOn.toIso8601String().split('T').first}',
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hexToColor(t.categoryColor).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      t.isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                      color: hexToColor(t.categoryColor),
                      size: 18,
                    ),
                  ),
                  trailing: Text(
                    '${t.isIncome ? '+' : '-'}${_fmtAmount(t.amount)} ₸',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: t.isIncome ? hig.success : hig.danger,
                    ),
                  ),
                  onTap: () => context.push(AppRoutes.transactions.path),
                ),
            ],
          );
        },
      ),

      // ── Family member breakdown (only in Семья scope) ──────────────
      if (_scope == Scope.family) ...[
        const SizedBox(height: 16),
        ref.watch(memberBreakdownProvider).maybeWhen(
              data: (rows) => rows.isEmpty
                  ? const SizedBox.shrink()
                  : InsetSection(
                      header: 'Расходы участников',
                      children: [
                        for (final row in rows)
                          InsetTile(
                            title: row.fullName,
                            trailing: Text(
                              '-${_fmtAmount(row.expense)} ₸',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: hig.danger,
                              ),
                            ),
                          ),
                      ],
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
      ],

      const SizedBox(height: 16),
    ];

    return LargeTitleScaffold(
      title: 'Главная',
      slivers: slivers,
    );
  }

  static String _fmtAmount(double v) =>
      NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0)
          .format(v.abs());
}

// ── Flat balance card ──────────────────────────────────────────────────────────

class _FlatBalanceCard extends StatelessWidget {
  const _FlatBalanceCard({
    required this.hig,
    required this.net,
    required this.income,
    required this.expense,
  });

  final HigColors hig;
  final double net;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0);
    final theme = Theme.of(context);
    return _BalanceCardShell(
      hig: hig,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Баланс',
            style: TextStyle(fontSize: 13, color: hig.secondaryLabel),
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: net),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              '${fmt.format(v)} ₸',
              style: (theme.textTheme.displayLarge ?? const TextStyle(fontSize: 38))
                  .copyWith(
                    color: hig.label,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _BalanceStat(
                label: 'Доход',
                value: '+${fmt.format(income)} ₸',
                color: hig.success,
                icon: Icons.south_west_rounded,
              ),
              const SizedBox(width: 12),
              _BalanceStat(
                label: 'Расход',
                value: '-${fmt.format(expense)} ₸',
                color: hig.danger,
                icon: Icons.north_east_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceCardShell extends StatelessWidget {
  const _BalanceCardShell({required this.hig, required this.child});
  final HigColors hig;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hig.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Flat spending chart card ───────────────────────────────────────────────────

class _FlatChartCard extends StatelessWidget {
  const _FlatChartCard({
    required this.hig,
    required this.points,
  });

  final HigColors hig;
  final List<TrendPointModel> points;

  /// Abbreviate "YYYY-MM" → "Jan", "Feb", etc.
  static String _monthLabel(String yyyyMm) {
    final parts = yyyyMm.split('-');
    if (parts.length < 2) return yyyyMm;
    const names = [
      '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    final m = int.tryParse(parts[1]) ?? 0;
    return (m >= 1 && m <= 12) ? names[m] : parts[1];
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern();
    final totalThisMonth = points.isEmpty ? 0.0 : points.last.expense;

    return _ChartShell(
      hig: hig,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Тренд расходов',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: hig.label,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${fmt.format(totalThisMonth)} ₸ в этом месяце',
            style: TextStyle(fontSize: 13, color: hig.secondaryLabel),
          ),
          const SizedBox(height: 16),
          if (points.isEmpty)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'Пока нет данных за период',
                  style: TextStyle(
                    fontSize: 14,
                    color: hig.secondaryLabel,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: LineChart(
                _chartData(hig),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
              ),
            ),
        ],
      ),
    );
  }

  LineChartData _chartData(HigColors hig) {
    // fl_chart needs ≥2 spots for a visible line; duplicate single point.
    final effective = points.length == 1
        ? [points.first, points.first]
        : points;

    final spots = <FlSpot>[
      for (var i = 0; i < effective.length; i++)
        FlSpot(i.toDouble(), effective[i].expense),
    ];

    return LineChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final idx = value.round();
              if (idx < 0 || idx >= effective.length) {
                return const SizedBox.shrink();
              }
              // Show label only at first, last, and one middle point to
              // avoid crowding when there are many months.
              final showIndices = {
                0,
                effective.length - 1,
                effective.length ~/ 2,
              };
              if (!showIndices.contains(idx)) return const SizedBox.shrink();
              return Text(
                _monthLabel(effective[idx].month),
                style: TextStyle(fontSize: 10, color: hig.secondaryLabel),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => hig.label,
          tooltipRoundedRadius: 10,
          getTooltipItems: (touchedSpots) => touchedSpots
              .map((s) => LineTooltipItem(
                    s.y.toStringAsFixed(0),
                    TextStyle(color: hig.card, fontSize: 12),
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
          color: hig.accent,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                hig.accent.withValues(alpha: 0.22),
                hig.accent.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartShell extends StatelessWidget {
  const _ChartShell({required this.hig, required this.child});
  final HigColors hig;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hig.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

// ── Goal tile ──────────────────────────────────────────────────────────────────

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.hig,
    required this.title,
    required this.current,
    required this.target,
    required this.color,
  });

  final HigColors hig;
  final String title;
  final double current;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0);
    final progress = (current / target).clamp(0.0, 1.0);
    final pct = '${(progress * 100).toStringAsFixed(0)}%';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 17, color: hig.label),
                ),
              ),
              Text(
                '$pct · ${fmt.format(current)} / ${fmt.format(target)} ₸',
                style: TextStyle(fontSize: 12, color: hig.secondaryLabel),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 6, color: hig.separator),
                  FractionallySizedBox(
                    widthFactor: v,
                    child: Container(height: 6, color: color),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
