class SummaryModel {
  const SummaryModel({
    required this.income,
    required this.expense,
    required this.net,
  });

  factory SummaryModel.fromJson(Map<String, dynamic> json) => SummaryModel(
        income: (json['income'] as num).toDouble(),
        expense: (json['expense'] as num).toDouble(),
        net: (json['net'] as num).toDouble(),
      );

  final double income;
  final double expense;
  final double net;
}

class CategoryBreakdownModel {
  const CategoryBreakdownModel({
    required this.categoryId,
    required this.name,
    required this.total,
    required this.percentage,
    this.color,
  });

  factory CategoryBreakdownModel.fromJson(Map<String, dynamic> json) =>
      CategoryBreakdownModel(
        categoryId: json['categoryId'] as String,
        name: json['name'] as String,
        total: (json['total'] as num).toDouble(),
        percentage: (json['percentage'] as num).toDouble(),
        color: json['color'] as String?,
      );

  final String categoryId;
  final String name;
  final double total;
  final double percentage;
  final String? color;
}

class TrendPointModel {
  const TrendPointModel({
    required this.month,
    required this.income,
    required this.expense,
  });

  factory TrendPointModel.fromJson(Map<String, dynamic> json) =>
      TrendPointModel(
        month: json['month'] as String,
        income: (json['income'] as num).toDouble(),
        expense: (json['expense'] as num).toDouble(),
      );

  final String month; // YYYY-MM
  final double income;
  final double expense;
}
