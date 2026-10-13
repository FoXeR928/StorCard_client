class ServerCard {
  const ServerCard({
    required this.id,
    required this.name,
    required this.barcode,
    this.about,
    this.image,
  });

  final String id;
  final String name;
  final String barcode;
  final String? about;
  final String? image;

  factory ServerCard.fromJson(Map<String, dynamic> j) => ServerCard(
    id: _s(j['id'] ?? j['card_id'] ?? j['uuid']) ?? '',
    name: _s(j['name']) ?? '',
    about: _s(j['about']),
    barcode: _s(j['barcode']) ?? '',
    image: _s(j['image']),
  );

  bool get isEmpty => id.isEmpty && name.isEmpty && barcode.isEmpty;

  static String? _s(dynamic v) => v?.toString();
}
