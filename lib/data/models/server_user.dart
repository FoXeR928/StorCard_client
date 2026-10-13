class ServerUser {
  const ServerUser({
    required this.login,
    required this.userName,
    this.isAdmin = false,
  });

  final String login;
  final String userName;
  final bool isAdmin;

  factory ServerUser.fromJson(Map<String, dynamic> j) => ServerUser(
    login: (j['login'] ?? j['username'] ?? '').toString(),
    userName: (j['user_name'] ?? j['name'] ?? j['login'] ?? '').toString(),
    isAdmin: (j['is_admin'] ?? j['isAdmin'] ?? false) == true,
  );
}
