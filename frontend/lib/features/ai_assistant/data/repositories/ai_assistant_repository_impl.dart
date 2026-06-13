import '../../domain/entities/ai_message.dart';
import '../../domain/entities/insight_model.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../data_sources/ai_remote_data_source.dart';
import '../dto/ai_dtos.dart';

class AiAssistantRepositoryImpl implements AiAssistantRepository {
  AiAssistantRepositoryImpl(this._remote);
  final AiRemoteDataSource _remote;

  @override
  Future<AiMessage> sendMessage(String message, List<AiMessage> history) =>
      _remote.sendMessage(message, history);

  @override
  Future<List<InsightModel>> getFinancialInsights() => _remote.getFinancialInsights();

  @override
  Future<BudgetAnalysis> analyzeBudget() => _remote.analyzeBudget();

  @override
  Future<SavingsPlan> savingsPlan({
    required String eventName,
    required DateTime eventDate,
    required double targetAmount,
    double? savedAmount,
  }) =>
      _remote.savingsPlan({
        'eventName': eventName,
        'eventDate': eventDate.toIso8601String().split('T').first,
        'targetAmount': targetAmount,
        if (savedAmount != null) 'savedAmount': savedAmount,
      });

  @override
  Future<List<Reminder>> getReminders() => _remote.getReminders();

  @override
  Future<Reminder> createReminder({
    required String eventName,
    required DateTime eventDate,
    double? targetAmount,
    double? savedAmount,
  }) =>
      _remote.createReminder({
        'eventName': eventName,
        'eventDate': eventDate.toIso8601String().split('T').first,
        if (targetAmount != null) 'targetAmount': targetAmount,
        if (savedAmount != null) 'savedAmount': savedAmount,
      });

  @override
  Future<void> deleteReminder(String id) => _remote.deleteReminder(id);
}
