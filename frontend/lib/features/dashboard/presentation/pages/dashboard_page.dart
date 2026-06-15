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
import '../../../../core/errors/error_text.dart';
import '../../../../core/utils/hex_color.dart';
import '../../../goals/presentation/providers/goals_providers.dart';
import '../../../statistics/data/models/statistics_models.dart';
import '../../../statistics/presentation/providers/statistics_providers.dart';
import '../../../transactions/presentation/providers/finance_providers.dart';
import '../../../transactions/presentation/widgets/transaction_form_sheet.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Scope _scope = Scope.personal;

  /// Сбрасывает данные главного экрана и дожидается их перезагрузки —
  /// для pull-to-refresh и после добавления операции.
  Future<void> _refresh() async {
    ref
      ..invalidate(summaryProvider(_scope))
      ..invalidate(trendProvider(_scope))
      ..invalidate(transactionsProvider(_scope))
      ..invalidate(goalsProvider(_scope))
      ..invalidate(memberBreakdownProvider);
    await Future.wait<void>([
      _settle(ref.read(summaryProvider(_scope).future)),
      _settle(ref.read(trendProvider(_scope).future)),
      _settle(ref.read(transactionsProvider(_scope).future)),
      _settle(ref.read(goalsProvider(_scope).future)),
    ]);
  }

  /// Дожидается future, проглатывая ошибку: её покажет соответствующая секция.
  static Future<void> _settle(Future<Object?> f) async {
    try {
      await f;
    } catch (_) {
      // намеренно: ошибку отрисует error-состояние секции
    }
  }

  Future<void> _addTransaction() async {
    final created = await showTransactionForm(context);
    if (!mounted) return;
    if (created ?? false) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);

    final summary = ref.watch(summaryProvider(_scope));
    final trend = ref.watch(trendProvider(_scope));
    final txs = ref.watch(transactionsProvider(_scope));
    final goals = ref.watch(goalsProvider(_scope));

    // Кроссфейд между состояниями секции (loading→data→error). Мгновенно при
    // «уменьшить движение». Ключ меняется по состоянию — он и триггерит смену.
    final secDur = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 220);
    Widget sectioned(String name, AsyncValue<Object?> v, Widget child) {
      final state = v.isLoading ? '$name-l' : (v.hasError ? '$name-e' : '$name-d');
      return AnimatedSwitcher(
        duration: secDur,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        child: KeyedSubtree(key: ValueKey(state), child: child),
      );
    }

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
      sectioned('balance', summary, summary.when(
        loading: () => const _BalanceSkeleton(),
        error: (e, _) => _BalanceCardShell(
          hig: hig,
          child: _ErrorContent(
            hig: hig,
            message: errorText(e),
            onRetry: () => ref.invalidate(summaryProvider(_scope)),
          ),
        ),
        data: (s) => _FlatBalanceCard(
          hig: hig,
          net: s.net,
          income: s.income,
          expense: s.expense,
        ),
      )),

      const SizedBox(height: 16),

      // ── Spending trend chart ───────────────────────────────────────
      sectioned('trend', trend, trend.when(
        loading: () => const _ChartSkeleton(),
        error: (e, _) => _ChartShell(
          hig: hig,
          child: _ErrorContent(
            hig: hig,
            title: 'Тренд расходов',
            message: errorText(e),
            onRetry: () => ref.invalidate(trendProvider(_scope)),
          ),
        ),
        data: (points) => _FlatChartCard(
          hig: hig,
          points: points,
        ),
      )),

      const SizedBox(height: 16),

      // ── Goals ──────────────────────────────────────────────────────
      sectioned('goals', goals, goals.when(
        loading: () => const _ListSkeleton(header: 'Цели'),
        error: (e, _) => InsetSection(
          header: 'Цели',
          children: [
            _ErrorTile(
              hig: hig,
              message: errorText(e),
              onRetry: () => ref.invalidate(goalsProvider(_scope)),
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
      )),

      const SizedBox(height: 16),

      // ── Recent transactions ────────────────────────────────────────
      sectioned('txs', txs, txs.when(
        loading: () => const _ListSkeleton(header: 'Недавние операции'),
        error: (e, _) => InsetSection(
          header: 'Недавние операции',
          children: [
            _ErrorTile(
              hig: hig,
              message: errorText(e),
              onRetry: () => ref.invalidate(transactionsProvider(_scope)),
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
                  subtitle: _formatDate(t.occurredOn),
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
      )),

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
      onRefresh: _refresh,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTransaction,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      slivers: slivers,
    );
  }

  static String _fmtAmount(double v) =>
      NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0)
          .format(v.abs());

  /// Дата в формате «15 июн 2026». Локаль `ru` для intl в приложении не
  /// инициализирована (поэтому и график рисует месяцы вручную), так что
  /// форматируем без intl-locale, чтобы не словить LocaleDataException.
  static String _formatDate(DateTime d) {
    const months = [
      '', 'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    final m = (d.month >= 1 && d.month <= 12) ? months[d.month] : '${d.month}';
    return '${d.day} $m ${d.year}';
  }
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
    final counterDur = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 800);
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
            duration: counterDur,
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
                hig: hig,
                label: 'Доход',
                value: '+${fmt.format(income)} ₸',
                color: hig.success,
                icon: Icons.south_west_rounded,
              ),
              const SizedBox(width: 12),
              _BalanceStat(
                hig: hig,
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
    required this.hig,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final HigColors hig;
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    // Цвет несёт иконка и знак ±; текст — высококонтрастный label/secondaryLabel,
    // чтобы суммы статов проходили WCAG AA (зелёный на белом фоне его проваливал).
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
                  style: TextStyle(fontSize: 12, color: hig.secondaryLabel),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hig.label,
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

  /// Abbreviate "YYYY-MM" → "янв", "фев", etc.
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
    final chartDur = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 600);

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
                duration: chartDur,
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
    final barDur = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 800);
    // target может прийти 0 → защищаемся от деления на ноль / NaN в widthFactor.
    final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    final pct = '${(progress * 100).toStringAsFixed(0)}%';
    final done = progress >= 1.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (done) ...[
                Icon(Icons.emoji_events_rounded, color: hig.success, size: 16),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 17, color: hig.label),
                ),
              ),
              Text(
                done
                    ? 'Цель достигнута'
                    : '$pct · ${fmt.format(current)} / ${fmt.format(target)} ₸',
                style: TextStyle(
                  fontSize: 12,
                  color: done ? hig.success : hig.secondaryLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: barDur,
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 6, color: hig.separator),
                  FractionallySizedBox(
                    widthFactor: v,
                    child: Container(height: 6, color: done ? hig.success : color),
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

// ── Error states ─────────────────────────────────────────────────────────────

/// Содержимое ошибки для карточек (баланс, график): сообщение + «Повторить».
class _ErrorContent extends StatelessWidget {
  const _ErrorContent({
    required this.hig,
    required this.message,
    required this.onRetry,
    this.title,
  });

  final HigColors hig;
  final String message;
  final VoidCallback onRetry;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: hig.label,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Icon(Icons.error_outline, color: hig.danger, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: hig.secondaryLabel, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onRetry,
            child: const Text('Повторить'),
          ),
        ),
      ],
    );
  }
}

/// Строка ошибки для секций-списков (Цели, Недавние операции).
class _ErrorTile extends StatelessWidget {
  const _ErrorTile({
    required this.hig,
    required this.message,
    required this.onRetry,
  });

  final HigColors hig;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return InsetTile(
      title: message,
      leading: Icon(Icons.error_outline, color: hig.danger),
      trailing: TextButton(
        onPressed: onRetry,
        child: const Text('Повторить'),
      ),
    );
  }
}

// ── Loading skeletons ──────────────────────────────────────────────────────────

/// Пульсирующая обёртка для скелетонов. Уважает «уменьшить движение».
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});
  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _c
        ..stop()
        ..value = 1.0;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1.0)
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.width, required this.height, this.radius = 6});
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: hig.separator,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _BalanceSkeleton extends StatelessWidget {
  const _BalanceSkeleton();

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    return _BalanceCardShell(
      hig: hig,
      child: const _Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBox(width: 64, height: 12),
            SizedBox(height: 12),
            _SkeletonBox(width: 180, height: 34, radius: 8),
            SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _SkeletonBox(width: double.infinity, height: 14)),
                SizedBox(width: 12),
                Expanded(child: _SkeletonBox(width: double.infinity, height: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    return _ChartShell(
      hig: hig,
      child: const _Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBox(width: 140, height: 16),
            SizedBox(height: 8),
            _SkeletonBox(width: 120, height: 12),
            SizedBox(height: 16),
            _SkeletonBox(width: double.infinity, height: 160, radius: 10),
          ],
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton({required this.header});
  final String header;

  @override
  Widget build(BuildContext context) {
    return InsetSection(
      header: header,
      children: [for (var i = 0; i < 3; i++) const _SkeletonRow()],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: _Shimmer(
        child: Row(
          children: [
            _SkeletonBox(width: 36, height: 36, radius: 8),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: 120, height: 14),
                  SizedBox(height: 6),
                  _SkeletonBox(width: 80, height: 12),
                ],
              ),
            ),
            SizedBox(width: 12),
            _SkeletonBox(width: 56, height: 14),
          ],
        ),
      ),
    );
  }
}
