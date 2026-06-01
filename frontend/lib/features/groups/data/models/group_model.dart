class GroupModel {
  const GroupModel({
    required this.id,
    required this.name,
    required this.type,
    required this.shared,
    this.icon,
    this.color,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        shared: json['shared'] as bool? ?? false,
        icon: json['icon'] as String?,
        color: json['color'] as String?,
      );

  final String id;
  final String name;
  final String type;
  final bool shared;
  final String? icon;
  final String? color;
}
