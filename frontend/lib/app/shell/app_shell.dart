import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/features/budgets/presentation/providers/budgets_providers.dart';
import 'package:aifb/features/goals/presentation/providers/goals_providers.dart';
import 'package:aifb/features/household/presentation/providers/household_providers.dart';
import 'package:aifb/features/statistics/presentation/providers/statistics_providers.dart';
import 'package:aifb/features/transactions/presentation/providers/finance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Сбрасывает кэш провайдеров выбранной вкладки. Страницы живут в IndexedStack
  /// и остаются подписанными на свои autoDispose-провайдеры, поэтому без сброса
  /// данные не перезапрашиваются. Инвалидация заставляет живую страницу
  /// подтянуть свежие данные при каждом переключении — без перезагрузки страницы.
  /// Прежние данные остаются видны до прихода новых (skipLoadingOnRefresh),
  /// поэтому мигания спиннера нет.
  void _refreshBranch(WidgetRef ref, int index) {
    switch (index) {
      case 0: // Главная
        ref
          ..invalidate(summaryProvider)
          ..invalidate(expenseByCategoryProvider)
          ..invalidate(trendProvider)
          ..invalidate(memberBreakdownProvider)
          ..invalidate(transactionsProvider)
          ..invalidate(goalsProvider);
      case 1: // Операции
        ref.invalidate(transactionsProvider);
      case 2: // Бюджеты
        ref.invalidate(budgetsProvider);
      case 3: // Цели
        ref
          ..invalidate(goalsProvider)
          ..invalidate(goalContributionsProvider);
      case 4: // Ещё (Семья и пр.)
        ref
          ..invalidate(myHouseholdProvider)
          ..invalidate(memberBreakdownProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hig = HigColors.of(context);
    return Scaffold(
      backgroundColor: hig.pageBackground,
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) {
          navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          );
          _refreshBranch(ref, i);
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Главная'),
          NavigationDestination(
              icon: Icon(Icons.swap_vert_outlined),
              selectedIcon: Icon(Icons.swap_vert_rounded),
              label: 'Операции'),
          NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart_rounded),
              label: 'Бюджеты'),
          NavigationDestination(
              icon: Icon(Icons.flag_outlined),
              selectedIcon: Icon(Icons.flag_rounded),
              label: 'Цели'),
          NavigationDestination(
              icon: Icon(Icons.more_horiz_outlined),
              selectedIcon: Icon(Icons.more_horiz_rounded),
              label: 'Ещё'),
        ],
      ),
    );
  }
}
