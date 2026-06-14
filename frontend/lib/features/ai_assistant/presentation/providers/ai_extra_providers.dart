import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dto/ai_dtos.dart';
import 'ai_dependency_provider.dart';

final budgetAnalysisProvider = FutureProvider.autoDispose<BudgetAnalysis>((ref) {
  return ref.watch(aiAssistantRepositoryProvider).analyzeBudget();
});

final remindersProvider = FutureProvider.autoDispose<List<Reminder>>((ref) {
  return ref.watch(aiAssistantRepositoryProvider).getReminders();
});

final digestProvider = FutureProvider.autoDispose<AiDigest>((ref) {
  return ref.watch(aiAssistantRepositoryProvider).digest();
});
