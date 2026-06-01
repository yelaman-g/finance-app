class RuleModel {
  const RuleModel({
    required this.id,
    required this.keyword,
    required this.categoryId,
    required this.categoryName,
  });

  factory RuleModel.fromJson(Map<String, dynamic> json) => RuleModel(
        id: json['id'] as String,
        keyword: json['keyword'] as String,
        categoryId: json['categoryId'] as String,
        categoryName: json['categoryName'] as String,
      );

  final String id;
  final String keyword;
  final String categoryId;
  final String categoryName;
}
