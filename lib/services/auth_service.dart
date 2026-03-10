// lib/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/env_config.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _roleKey = 'user_role';
  static const _keepSessionKey = 'keep_session';

  static Future<void> saveTokens({required String token}) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Intenta refrescar el token usando el endpoint /refresh-token.
  /// Retorna true si se refrescó exitosamente, false si falló.
  /// Solo se ejecuta si keepSession está activo y hay un token guardado.
  static Future<bool> tryRefreshToken() async {
    final keepSession = await getKeepSession();
    if (!keepSession) return false;

    final currentToken = await getToken();
    if (currentToken == null) return false;

    try {
      // Usamos un Dio separado para no pasar por los interceptores
      final refreshDio = Dio(BaseOptions(baseUrl: EnvConfig.apiUrl));

      final response = await refreshDio.post(
        '/auth-user/refresh-token',
        data: {'token': currentToken},
      );

      final newToken = response.data['token'];
      if (newToken != null) {
        await saveTokens(token: newToken);
        print('Token refrescado exitosamente.');
        return true;
      }
      return false;
    } catch (e) {
      print('Error al refrescar token: $e');
      return false;
    }
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
