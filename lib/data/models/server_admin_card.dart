class ServerAdminCard {
  const ServerAdminCard({
    required this.id,
    required this.name,
    required this.barcode,
    this.about,
    this.ownerLogin,
  });

  final String id;
  final String name;
  final String barcode;
  final String? about;
  final String? ownerLogin;

  factory ServerAdminCard.fromJson(Map<String, dynamic> j) => ServerAdminCard(
    id: (j['id'] ?? j['card_id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    barcode: (j['barcode'] ?? '').toString(),
    about: j['about'] as String?,
    ownerLogin: (j['owner_login'] ?? j['own_login'] ?? j['owner'] ?? j['login'])
        ?.toString(),
  );
}
