import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../models/dashboard_mock.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/balance_card.dart';
import '../widgets/family_activity_card.dart';
import '../widgets/goal_progress_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_transactions.dart';
import '../widgets/section_header.dart';
import '../widgets/spending_chart_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // TODO(domain): replace with Riverpod-fed providers from analytics/ai/family.
  static const _insights = <InsightItem>[
    InsightItem(
      title: 'Spending up 24%',
      body: 'Restaurants drove most of this month\'s increase. Consider a 80k₸ cap.',
      icon: Icons.trending_up_rounded,
      tint: AppColors.warning,
    ),
    InsightItem(
      title: 'Vacation goal on track',
      body: 'At current pace you\'ll reach Bali fund in 5 months.',
      icon: Icons.flight_takeoff_rounded,
      tint: AppColors.brand500,
    ),
    InsightItem(
      title: 'Subscription drift',
      body: '3 unused subscriptions detected. Save up to 12,400₸/mo.',
      icon: Icons.refresh_rounded,
      tint: AppColors.success,
    ),
  ];

  static const _txs = <TxItem>[
    TxItem(
      title: 'Magnum Cosmos',
      subtitle: 'Groceries · Today',
      amount: 18420,
      icon: Icons.shopping_bag_rounded,
      color: AppColors.brand500,
    ),
    TxItem(
      title: 'Salary',
      subtitle: 'Income · Yesterday',
      amount: 820000,
      icon: Icons.payments_rounded,
      color: AppColors.success,
      isIncome: true,
    ),
    TxItem(
      title: 'Yandex Taxi',
      subtitle: 'Transport · 2d ago',
      amount: 3100,
      icon: Icons.local_taxi_rounded,
      color: AppColors.warning,
    ),
    TxItem(
      title: 'Netflix',
      subtitle: 'Subscriptions · 3d ago',
      amount: 4990,
      icon: Icons.movie_rounded,
      color: AppColors.danger,
    ),
  ];

  static const _goals = <GoalItem>[
    GoalItem(
      title: 'Bali vacation',
      current: 1450000,
      target: 2500000,
      color: AppColors.brand500,
    ),
    GoalItem(
      title: 'Emergency fund',
      current: 620000,
      target: 1000000,
      color: AppColors.success,
    ),
  ];

  static const _members = <FamilyMemberItem>[
    FamilyMemberItem(
      name: 'Aibek S.',
      role: 'PARENT',
      color: AppColors.brand500,
      lastAction: 'Spent 18,420 ₸ at Magnum',
    ),
    FamilyMemberItem(
      name: 'Aisha S.',
      role: 'CHILD',
      color: AppColors.warning,
      lastAction: 'Reached 80% of weekly limit',
    ),
  ];

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
                      children:
                          _staggered(_buildSections(context, wide: wide)),
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
    final left = <Widget>[
      const BalanceCard(
        balance: 4287500,
        currency: '₸',
        delta: 0.082,
      ),
      const SizedBox(height: AppSpacing.lg),
      const QuickActions(),
      const SizedBox(height: AppSpacing.xl),
      const SpendingChartCard(),
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(
        title: 'AI insights',
        action: 'See all',
        onAction: () => context.go(AppRoutes.ai.path),
      ),
      const SizedBox(height: AppSpacing.md),
      const AiInsightsRow(items: _insights),
    ];
    final right = <Widget>[
      SectionHeader(
        title: 'Goals',
        action: 'Manage',
        onAction: () => _showSoon(context, 'Goals'),
      ),
      const SizedBox(height: AppSpacing.md),
      GoalProgressCard(goals: _goals),
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(
        title: 'Family activity',
        action: 'Open',
        onAction: () => _showSoon(context, 'Family activity'),
      ),
      const SizedBox(height: AppSpacing.md),
      FamilyActivityCard(members: _members),
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(
        title: 'Recent transactions',
        action: 'View all',
        onAction: () => context.go(AppRoutes.analytics.path),
      ),
      const SizedBox(height: AppSpacing.md),
      RecentTransactions(items: _txs),
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

  static void _showSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label — coming soon')));
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
