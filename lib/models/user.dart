class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;

  UserModel({required this.id, required this.name, required this.email, required this.role, this.avatarUrl});

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'],
        name: j['name'],
        email: j['email'],
    role: j['role'] ?? 'user',
    avatarUrl: j['avatar_url'] as String?,
      );
}
