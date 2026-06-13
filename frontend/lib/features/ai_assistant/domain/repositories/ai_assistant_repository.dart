import '../entities/ai_message.dart';
import '../entities/insight_model.dart';
import '../../data/dto/ai_dtos.dart';

abstract class AiAssistantRepository {
  Future<AiMessage> sendMessage(String message, List<AiMessage> history);
  Future<List<InsightModel>> getFinancialInsights();
  Future<BudgetAnalysis> analyzeBudget();
  Future<SavingsPlan> savingsPlan({
    required String eventName,
    required DateTime eventDate,
    required double targetAmount,
    double? savedAmount,
  });
  Future<List<Reminder>> getReminders();
  Future<Reminder> createReminder({
    required String eventName,
    required DateTime eventDate,
    double? targetAmount,
    double? savedAmount,
  });
  Future<void> deleteReminder(String id);
}
