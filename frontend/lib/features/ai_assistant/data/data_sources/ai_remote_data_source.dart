import 'package:dio/dio.dart';
import '../../domain/entities/ai_message.dart';
import '../../domain/entities/insight_model.dart';

abstract class AiRemoteDataSource {
  Future<AiMessage> sendMessage(String message);
  Future<List<AiMessage>> getChatHistory();
  Future<List<InsightModel>> getFinancialInsights();
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  // ignore: unused_field
  final Dio _dio;

  AiRemoteDataSourceImpl(this._dio);

  @override
  Future<AiMessage> sendMessage(String message) async {
    // Mocked delay for a real feeling
    await Future<void>.delayed(const Duration(seconds: 2));
    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: 'I analyzed your recent transactions. You spent 15% less on dining out this month! Keep it up.',
      role: MessageRole.ai,
      timestamp: DateTime.now(),
      suggestedActions: ['View dining expenses', 'Set new budget limit'],
    );
  }

  @override
  Future<List<AiMessage>> getChatHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return [
      AiMessage(
        id: '1',
        content: 'Hello! I am your AI Financial Assistant. How can I help you today?',
        role: MessageRole.ai,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  @override
  Future<List<InsightModel>> getFinancialInsights() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return [
      InsightModel(
        id: '1',
        title: 'Upcoming Subscription',
        description: 'Your Netflix subscription (\$15.99) is due tomorrow.',
        type: InsightType.warning,
        createdAt: DateTime.now(),
      ),
      InsightModel(
        id: '2',
        title: 'Savings Potential',
        description: 'You can save \$120 this month if you maintain your current grocery spending rate.',
        type: InsightType.prediction,
        impactValue: 120.0,
        impactLabel: '+ \$120',
        createdAt: DateTime.now(),
      ),
      InsightModel(
        id: '3',
        title: 'Budget Milestone',
        description: 'You stayed under your entertainment budget for 3 consecutive months!',
        type: InsightType.achievement,
        createdAt: DateTime.now(),
      ),
    ];
  }
}
