class MemberBreakdownModel {
  const MemberBreakdownModel({
    required this.userId,
    required this.fullName,
    required this.income,
    required this.expense,
  });

  factory MemberBreakdownModel.fromJson(Map<String, dynamic> json) =>
      MemberBreakdownModel(
        userId: json['userId'] as String,
        fullName: json['fullName'] as String,
        income: (json['income'] as num).toDouble(),
        expense: (json['expense'] as num).toDouble(),
      );

  final String userId;
  final String fullName;
  final double income;
  final double expense;
}
