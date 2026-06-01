class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.system,
    this.icon,
    this.color,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        system: json['system'] as bool? ?? false,
        icon: json['icon'] as String?,
        color: json['color'] as String?,
      );

  final String id;
  final String name;
  final String type; // INCOME | EXPENSE
  final bool system;
  final String? icon;
  final String? color;
}
