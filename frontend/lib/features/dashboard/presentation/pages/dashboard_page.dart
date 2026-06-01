import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/domain/scope.dart';
import '../../../../core/utils/hex_color.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../goals/presentation/providers/goals_providers.dart';
import '../../../statistics/data/models/member_breakdown_model.dart';
import '../../../statistics/presentation/providers/statistics_providers.dart';
import '../../../transactions/presentation/providers/finance_providers.dart';
import '../models/dashboard_mock.dart';
import '../widgets/balance_card.dart';
import '../widgets/goal_progress_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_transactions.dart';
import '../widgets/section_header.dart';
import '../widgets/spending_chart_card.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Scope _scope = Scope.personal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 720;
              return CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: _TopBar()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.xxxl,
                    ),
                    sliver: SliverList.list(
                      children: _staggered(
                          _buildSections(context, wide: wide),),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context, {required bool wide}) {
    final summary = ref.watch(summaryProvider(_scope));
    final trend = ref.watch(trendProvider(_scope));
    final txs = ref.watch(transactionsProvider(_scope));
    final goals = ref.watch(goalsProvider(_scope));

    final scopeSelector = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<Scope>(
          segments: const [
            ButtonSegment(value: Scope.personal, label: Text('Личное')),
            ButtonSegment(value: Scope.family, label: Text('Семья')),
          ],
          selected: {_scope},
          onSelectionChanged: (s) => setState(() => _scope = s.first),
        ),
        const SizedBox(height: 16),
      ],
    );

    final balanceCard = summary.when(
      loading: () => const BalanceCard(
          balance: 0, currency: '₸', delta: 0, income: 0, expense: 0,),
      error: (_, __) => const BalanceCard(
          balance: 0, currency: '₸', delta: 0, income: 0, expense: 0,),
      data: (s) => BalanceCard(
        balance: s.net,
        currency: '₸',
        delta: 0,
        income: s.income,
        expense: s.expense,
      ),
    );

    final spendingCard = trend.when(
      loading: () =>
          const SpendingChartCard(monthly: [], totalThisMonth: 0),
      error: (_, __) =>
          const SpendingChartCard(monthly: [], totalThisMonth: 0),
      data: (points) => SpendingChartCard(
        monthly: points.map((p) => p.expense).toList(),
        totalThisMonth: points.isEmpty ? 0 : points.last.expense,
      ),
    );

    final recent = txs.when(
      loading: () => const SizedBox(
          height: 80, child: Center(child: CircularProgressIndicator()),),
      error: (e, _) => _ErrorBox(message: 'Операции: $e'),
      data: (page) => RecentTransactions(
        items: page.items
            .take(5)
            .map((t) => TxItem(
                  title: t.categoryName ?? '—',
                  subtitle:
                      '${t.isIncome ? 'Доход' : 'Расход'} · ${t.occurredOn.toIso8601String().split('T').first}',
                  amount: t.amount,
                  icon: t.isIncome
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: hexToColor(t.categoryColor),
                  isIncome: t.isIncome,
                ),)
            .toList(),
      ),
    );

    final goalsCard = goals.when(
      loading: () => const SizedBox(
          height: 80, child: Center(child: CircularProgressIndicator()),),
      error: (e, _) => _ErrorBox(message: 'Цели: $e'),
      data: (list) => list.isEmpty
          ? const _ErrorBox(message: 'Целей пока нет')
          : GoalProgressCard(
              goals: list
                  .take(3)
                  .map((g) => GoalItem(
                        title: g.name,
                        current: g.savedAmount,
                        target: g.targetAmount,
                        color: hexToColor(g.color),
                      ),)
                  .toList(),
            ),
    );

    final memberBreakdown = _scope == Scope.family
        ? ref.watch(memberBreakdownProvider).maybeWhen(
            data: (rows) => _MemberBreakdownCard(rows: rows),
            orElse: () => const SizedBox.shrink(),
          )
        : null;

    final left = <Widget>[
      scopeSelector,
      balanceCard,
      const SizedBox(height: AppSpacing.lg),
      const QuickActions(),
      const SizedBox(height: AppSpacing.xl),
      spendingCard,
    ];
    final right = <Widget>[
      SectionHeader(
        title: 'Goals',
        action: 'Manage',
        onAction: () => context.push(AppRoutes.family.path),
      ),
      const SizedBox(height: AppSpacing.md),
      goalsCard,
      if (memberBreakdown != null) ...[
        const SizedBox(height: AppSpacing.xl),
        memberBreakdown,
      ],
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(
        title: 'Recent transactions',
        action: 'View all',
        onAction: () => context.push(AppRoutes.transactions.path),
      ),
      const SizedBox(height: AppSpacing.md),
      recent,
    ];
    if (!wide) return [...left, const SizedBox(height: AppSpacing.xl), ...right];
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: left)),
          const SizedBox(width: AppSpacing.xl),
          Expanded(child: Column(children: right)),
        ],
      ),
    ];
  }

  List<Widget> _staggered(List<Widget> items) {
    return [
      for (var i = 0; i < items.length; i++)
        items[i].animate(delay: (60 * i).ms).fadeIn(duration: 380.ms).slideY(
              begin: 0.04,
              end: 0,
              curve: Curves.easeOutCubic,
            ),
    ];
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(message, style: AppTypography.caption),
    );
  }
}

class _MemberBreakdownCard extends StatelessWidget {
  const _MemberBreakdownCard({required this.rows});

  final List<MemberBreakdownModel> rows;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Расходы участников', style: AppTypography.title),
          const SizedBox(height: AppSpacing.md),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(row.fullName, style: AppTypography.body),
                  Text(
                    '-${fmt.format(row.expense)} ₸',
                    style: AppTypography.body.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isAdmin = user?.roles.contains('ADMIN') ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.brand500, AppColors.brand400],
              ),
            ),
            child: Text(
              'AS',
              style: AppTypography.title.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good evening',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.graphite500,
                  ),
                ),
                Text(user?.fullName ?? 'Aibek', style: AppTypography.h2),
              ],
            ),
          ),
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: _IconBubble(
                icon: Icons.admin_panel_settings_rounded,
                onTap: () => context.push(AppRoutes.admin.path),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: _IconBubble(
              icon: Icons.group_rounded,
              onTap: () => context.push(AppRoutes.family.path),
            ),
          ),
          _IconBubble(
            icon: Icons.notifications_none_rounded,
            badge: true,
            onTap: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('No new notifications')),
                );
            },
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, this.badge = false, this.onTap});
  final IconData icon;
  final bool badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.graphite700),
          ),
          if (badge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
