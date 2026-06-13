import 'package:aifb/app/theme/app_theme.dart';
import 'package:aifb/features/ai_assistant/data/dto/ai_dtos.dart';
import 'package:aifb/features/ai_assistant/domain/entities/ai_message.dart';
import 'package:aifb/features/ai_assistant/domain/entities/insight_model.dart';
import 'package:aifb/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:aifb/features/ai_assistant/presentation/providers/ai_dependency_provider.dart';
import 'package:aifb/features/ai_assistant/presentation/screens/ai_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAiRepository implements AiAssistantRepository {
  @override
  Future<AiMessage> sendMessage(String message, List<AiMessage> history) async =>
      AiMessage(
        id: '1',
        content: 'ok',
        role: MessageRole.ai,
        timestamp: DateTime.now(),
      );

  @override
  Future<List<InsightModel>> getFinancialInsights() async => [];

  @override
  Future<BudgetAnalysis> analyzeBudget() async =>
      const BudgetAnalysis(analysis: '', tips: []);

  @override
  Future<SavingsPlan> savingsPlan({
    required String eventName,
    required DateTime eventDate,
    required double targetAmount,
    double? savedAmount,
  }) async =>
      const SavingsPlan(
          monthlyAmount: 0,
          monthsRemaining: 0,
          feasible: false,
          advice: '');

  @override
  Future<List<Reminder>> getReminders() async => [];

  @override
  Future<Reminder> createReminder({
    required String eventName,
    required DateTime eventDate,
    double? targetAmount,
    double? savedAmount,
  }) async =>
      Reminder(
        id: '1',
        eventName: eventName,
        eventDate: eventDate,
        savedAmount: 0,
        daysUntil: 0,
        monthsRemaining: 0,
        monthlyNeeded: 0,
        progressPercent: 0,
      );

  @override
  Future<void> deleteReminder(String id) async {}
}

void main() {
  testWidgets('AiHomeScreen shows three tabs', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        aiAssistantRepositoryProvider.overrideWithValue(_FakeAiRepository()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const AiHomeScreen()),
    ));
    // Pump once to resolve async providers and fire zero-duration animation timers.
    await tester.pump();
    // Pump again with a non-zero duration to advance past any animation timers
    // started by flutter_animate (e.g. shimmer repeat in AiAssistantScreen).
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('Чат'), findsOneWidget);
    expect(find.text('Анализ'), findsOneWidget);
    expect(find.text('Напоминания'), findsOneWidget);
  });
}
