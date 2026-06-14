class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.title,
    required this.checked,
    required this.createdBy,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> j) => ShoppingItem(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        checked: j['checked'] as bool? ?? false,
        createdBy: j['createdBy'] as String? ?? '',
      );

  final String id;
  final String title;
  final bool checked;
  final String createdBy;
}
