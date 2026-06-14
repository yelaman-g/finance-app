class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.amount,
    required this.spent,
    required this.percentage,
    required this.status,
    required this.shared,
    this.notifyThresholdPercent = 80,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as String,
        targetType: json['targetType'] as String,
        targetId: json['targetId'] as String,
        targetName: json['targetName'] as String,
        amount: (json['amount'] as num).toDouble(),
        spent: (json['spent'] as num).toDouble(),
        percentage: (json['percentage'] as num).toDouble(),
        status: json['status'] as String,
        shared: json['shared'] as bool? ?? false,
        notifyThresholdPercent:
            (json['notifyThresholdPercent'] as num?)?.toInt() ?? 80,
      );

  final String id;
  final String targetType;
  final String targetId;
  final String targetName;
  final double amount;
  final double spent;
  final double percentage;
  final String status;
  final bool shared;
  final int notifyThresholdPercent;
}
