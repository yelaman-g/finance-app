enum InsightType { recommendation, warning, prediction, achievement }

class InsightModel {
  final String id;
  final String title;
  final String description;
  final InsightType type;
  final double? impactValue;
  final String? impactLabel;
  final DateTime createdAt;

  const InsightModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.impactValue,
    this.impactLabel,
    required this.createdAt,
  });
}
