import 'package:dio/dio.dart';

import '../../domain/entities/user.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthSession> login(String email, String password) async {
    final res = await _dio.post<Map<String, dynamic>>('/auth/login', data: {'email': email, 'password': password});
    return AuthSession.fromJson(res.data!);
  }

  Future<AuthSession> register(String name, String email, String password, UserRole role) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password, 'role': UserModel.roleToJson(role)},
    );
    return AuthSession.fromJson(res.data!);
  }

  Future<User> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/auth/me');
    return UserModel.fromJson(res.data!);
  }

  Future<User> updateMe({String? name, String? email}) async {
    final res = await _dio.patch<Map<String, dynamic>>('/auth/me', data: {'name': ?name, 'email': ?email});
    return UserModel.fromJson(res.data!);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _dio.patch<void>('/auth/me/password', data: {'currentPassword': currentPassword, 'newPassword': newPassword});
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post<void>('/auth/logout', data: {'refreshToken': refreshToken});
  }
}
