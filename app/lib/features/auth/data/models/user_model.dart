import '../../domain/entities/user.dart';

/// Conversion JSON ↔ entité. Le domaine ne connaît pas le JSON.
abstract final class UserModel {
  static User fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] == 'teacher' ? UserRole.teacher : UserRole.student,
    level: (json['level'] as num?)?.toInt() ?? 1,
  );

  static Map<String, dynamic> toJson(User user) => {
    'id': user.id,
    'name': user.name,
    'email': user.email,
    'role': roleToJson(user.role),
    'level': user.level,
  };

  static String roleToJson(UserRole role) => role == UserRole.teacher ? 'teacher' : 'student';
}

/// Réponse de /auth/login et /auth/register.
class AuthSession {
  const AuthSession({required this.user, required this.accessToken, required this.refreshToken});

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
  );

  final User user;
  final String accessToken;
  final String refreshToken;
}
