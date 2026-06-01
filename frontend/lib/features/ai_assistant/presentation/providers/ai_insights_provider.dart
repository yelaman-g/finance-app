import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/insight_model.dart';
import 'ai_dependency_provider.dart';

part 'ai_insights_provider.g.dart';

@riverpod
class AiInsightsNotifier extends _$AiInsightsNotifier {
  @override
  FutureOr<List<InsightModel>> build() async {
    final repo = ref.watch(aiAssistantRepositoryProvider);
    return repo.getFinancialInsights();
  }
}
