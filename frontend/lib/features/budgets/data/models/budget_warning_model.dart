class BudgetWarningModel {
  const BudgetWarningModel({
    required this.targetType,
    required this.targetName,
    required this.amount,
    required this.spent,
    required this.percentage,
    required this.status,
  });

  factory BudgetWarningModel.fromJson(Map<String, dynamic> json) =>
      BudgetWarningModel(
        targetType: json['targetType'] as String,
        targetName: json['targetName'] as String,
        amount: (json['amount'] as num).toDouble(),
        spent: (json['spent'] as num).toDouble(),
        percentage: (json['percentage'] as num).toDouble(),
        status: json['status'] as String,
      );

  final String targetType;
  final String targetName;
  final double amount;
  final double spent;
  final double percentage;
  final String status;
}
