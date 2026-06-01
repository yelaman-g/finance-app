import '../../domain/entities/ai_message.dart';
import '../../domain/entities/insight_model.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../data_sources/ai_remote_data_source.dart';

class AiAssistantRepositoryImpl implements AiAssistantRepository {
  final AiRemoteDataSource _remoteDataSource;

  AiAssistantRepositoryImpl(this._remoteDataSource);

  @override
  Future<AiMessage> sendMessage(String message) {
    return _remoteDataSource.sendMessage(message);
  }

  @override
  Future<List<AiMessage>> getChatHistory() {
    return _remoteDataSource.getChatHistory();
  }

  @override
  Future<List<InsightModel>> getFinancialInsights() {
    return _remoteDataSource.getFinancialInsights();
  }
}
