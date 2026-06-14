class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.reserved,
    this.note,
    this.reservedBy,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> j) => WishlistItem(
        id: j['id'] as String? ?? '',
        ownerId: j['ownerId'] as String? ?? '',
        ownerName: j['ownerName'] as String? ?? '',
        title: j['title'] as String? ?? '',
        note: j['note'] as String?,
        reserved: j['reserved'] as bool? ?? false,
        reservedBy: j['reservedBy'] as String?,
      );

  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String? note;
  final bool reserved;
  final String? reservedBy;
}
