import 'package:aifb/features/budgets/data/models/budget_warning_model.dart';

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
    this.budgetWarnings = const [],
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
        budgetWarnings: (json['budgetWarnings'] as List?)
                ?.map(
                  (e) =>
                      BudgetWarningModel.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            const [],
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
  final List<BudgetWarningModel> budgetWarnings;

  bool get isIncome => type == 'INCOME';
}
