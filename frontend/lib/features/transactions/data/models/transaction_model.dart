class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.occurredOn,
    this.categoryName,
    this.categoryColor,
    this.categoryIcon,
    this.note,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        type: json['type'] as String,
        amount: (json['amount'] as num).toDouble(),
        occurredOn: DateTime.parse(json['occurredOn'] as String),
        categoryName: json['categoryName'] as String?,
        categoryColor: json['categoryColor'] as String?,
        categoryIcon: json['categoryIcon'] as String?,
        note: json['note'] as String?,
      );

  final String id;
  final String categoryId;
  final String type; // INCOME | EXPENSE
  final double amount;
  final DateTime occurredOn;
  final String? categoryName;
  final String? categoryColor;
  final String? categoryIcon;
  final String? note;

  bool get isIncome => type == 'INCOME';
}
