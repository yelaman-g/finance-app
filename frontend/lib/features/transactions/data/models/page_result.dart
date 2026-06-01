class PageResult<T> {
  const PageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
    required this.hasNext,
  });

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) =>
      PageResult<T>(
        items: (json['items'] as List)
            .map((e) => itemFromJson(e as Map<String, dynamic>))
            .toList(),
        page: json['page'] as int,
        size: json['size'] as int,
        total: json['total'] as int,
        hasNext: json['hasNext'] as bool,
      );

  final List<T> items;
  final int page;
  final int size;
  final int total;
  final bool hasNext;
}
