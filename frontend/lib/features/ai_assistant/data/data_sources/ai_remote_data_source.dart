import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/ai_message.dart';
import '../../domain/entities/insight_model.dart';
import '../dto/ai_dtos.dart';

abstract class AiRemoteDataSource {
  Future<AiMessage> sendMessage(String message, List<AiMessage> history);
  Future<List<InsightModel>> getFinancialInsights();
  Future<BudgetAnalysis> analyzeBudget();
  Future<SavingsPlan> savingsPlan(Map<String, dynamic> body);
  Future<List<Reminder>> getReminders();
  Future<Reminder> createReminder(Map<String, dynamic> body);
  Future<void> deleteReminder(String id);
  Future<AiDigest> digest();
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  AiRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  String _role(MessageRole r) => r == MessageRole.user ? 'user' : 'ai';

  @override
  Future<AiMessage> sendMessage(String message, List<AiMessage> history) async {
    final msgs = <Map<String, dynamic>>[
      for (final m in history)
        if (!m.isTyping) {'role': _role(m.role), 'content': m.content},
      {'role': 'user', 'content': message},
    ];
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.aiChat,
      data: {'messages': msgs},
    );
    final d = _unwrap(res.data);
    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: d['content'] as String? ?? '',
      role: MessageRole.ai,
      timestamp: DateTime.now(),
      suggestedActions:
          (d['suggestedActions'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  @override
  Future<List<InsightModel>> getFinancialInsights() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.aiInsights);
    return _unwrapList(res.data).map((j) => _insight(j as Map<String, dynamic>)).toList();
  }

  @override
  Future<BudgetAnalysis> analyzeBudget() async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.aiAnalyzeBudget,
      data: <String, dynamic>{},
    );
    return BudgetAnalysis.fromJson(_unwrap(res.data));
  }

  @override
  Future<SavingsPlan> savingsPlan(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(ApiEndpoints.aiSavingsPlan, data: body);
    return SavingsPlan.fromJson(_unwrap(res.data));
  }

  @override
  Future<List<Reminder>> getReminders() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.aiReminders);
    return _unwrapList(res.data).map((j) => Reminder.fromJson(j as Map<String, dynamic>)).toList();
  }

  @override
  Future<Reminder> createReminder(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(ApiEndpoints.aiReminders, data: body);
    return Reminder.fromJson(_unwrap(res.data));
  }

  @override
  Future<void> deleteReminder(String id) async {
    await _dio.delete<void>('${ApiEndpoints.aiReminders}/$id');
  }

  @override
  Future<AiDigest> digest() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.aiDigest);
    return AiDigest.fromJson(_unwrap(res.data));
  }

  InsightModel _insight(Map<String, dynamic> j) {
    final typeStr = j['type'] as String? ?? 'recommendation';
    final type = InsightType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => InsightType.recommendation,
    );
    return InsightModel(
      id: j['id']?.toString() ?? '',
      title: j['title'] as String? ?? '',
      description: j['description'] as String? ?? '',
      type: type,
      impactValue: (j['impactValue'] as num?)?.toDouble(),
      impactLabel: j['impactLabel'] as String?,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is Map<String, dynamic>) return data;
    throw DioException(requestOptions: RequestOptions(), message: 'Malformed envelope');
  }

  List<dynamic> _unwrapList(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is List) return data;
    throw DioException(requestOptions: RequestOptions(), message: 'Malformed envelope');
  }
}
