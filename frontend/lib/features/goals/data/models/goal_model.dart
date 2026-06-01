class GoalModel {
  const GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.percentage,
    required this.status,
    this.deadline,
    this.icon,
    this.color,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
        id: json['id'] as String,
        name: json['name'] as String,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        savedAmount: (json['savedAmount'] as num).toDouble(),
        percentage: (json['percentage'] as num).toDouble(),
        status: json['status'] as String,
        deadline: json['deadline'] == null
            ? null
            : DateTime.parse(json['deadline'] as String),
        icon: json['icon'] as String?,
        color: json['color'] as String?,
      );

  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final double percentage;
  final String status; // ACTIVE | COMPLETED | ARCHIVED
  final DateTime? deadline;
  final String? icon;
  final String? color;
}

class ContributionModel {
  const ContributionModel({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.contributedOn,
    this.note,
  });

  factory ContributionModel.fromJson(Map<String, dynamic> json) =>
      ContributionModel(
        id: json['id'] as String,
        goalId: json['goalId'] as String,
        amount: (json['amount'] as num).toDouble(),
        contributedOn: DateTime.parse(json['contributedOn'] as String),
        note: json['note'] as String?,
      );

  final String id;
  final String goalId;
  final double amount;
  final DateTime contributedOn;
  final String? note;
}
