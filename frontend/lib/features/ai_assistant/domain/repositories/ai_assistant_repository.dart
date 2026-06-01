import '../entities/ai_message.dart';
import '../entities/insight_model.dart';

abstract class AiAssistantRepository {
  Future<AiMessage> sendMessage(String message);
  Future<List<AiMessage>> getChatHistory();
  Future<List<InsightModel>> getFinancialInsights();
}
