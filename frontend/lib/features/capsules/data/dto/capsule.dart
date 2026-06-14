class Capsule {
  const Capsule({
    required this.id,
    required this.title,
    required this.openDate,
    required this.locked,
    required this.createdBy,
    this.message,
  });

  factory Capsule.fromJson(Map<String, dynamic> j) => Capsule(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        openDate: DateTime.parse(j['openDate'] as String),
        locked: j['locked'] as bool? ?? true,
        message: j['message'] as String?,
        createdBy: j['createdBy'] as String? ?? '',
      );

  final String id;
  final String title;
  final DateTime openDate;
  final bool locked;
  final String? message;
  final String createdBy;
}
