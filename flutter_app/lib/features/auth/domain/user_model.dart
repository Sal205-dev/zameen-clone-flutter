/// Mirrors the user object returned by Django's login and /me/ endpoints.
class UserModel {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String role; // 'buyer' | 'agent' | 'admin'

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
  });

  bool get isAgent => role == 'agent';

  /// Parses the user object from the Django API response.
  /// Login response shape:  { "user": { "id": 1, "username": "...", ... } }
  /// /me/ response shape:   { "id": 1, "username": "...", ... }
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:       json['id'] as int,
      username: json['username'] as String,
      email:    json['email'] as String? ?? '',
      phone:    json['phone'] as String? ?? '',
      role:     json['role'] as String? ?? 'buyer',
    );
  }
}
