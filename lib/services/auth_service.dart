// lib/services/auth_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _roleKey = 'user_role';
  static const _keepSessionKey = 'keep_session'; // 🔥 Nueva llave

  static Future<void> saveTokens({required String token}) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<void> saveRole(double role) async {
    await _storage.write(key: _roleKey, value: role.toString());
  }

  // 🔥 Guardar si quiere mantener sesión
  static Future<void> saveKeepSession(bool keepSession) async {
    await _storage.write(key: _keepSessionKey, value: keepSession.toString());
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<double?> getUserRole() async {
    final roleString = await _storage.read(key: _roleKey);
    if (roleString != null) {
      return double.tryParse(roleString);
    }
    return null;
  }

  // 🔥 Leer si quiere mantener sesión
  static Future<bool> getKeepSession() async {
    final value = await _storage.read(key: _keepSessionKey);
    return value == 'true';
  }

  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _keepSessionKey); // Limpiamos también esto
  }
}
