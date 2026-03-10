import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/query_cache.dart';

// El equivalente a tu interfaz User en React
class UserModel {
  final String id;
  final String name;
  final String email;
  final double role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      // Aseguramos que se parsee como double incluso si la API manda un int
      role: (json['role'] as num).toDouble(),
    );
  }
}

// El equivalente a tu AuthContext
class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = true;
  Timer? _refreshTimer;

  /// Intervalo para refrescar el token proactivamente.
  /// El token dura 6 horas; lo refrescamos a las 5.5 horas para
  /// evitar que expire mientras el usuario está usando la app.
  static const _refreshInterval = Duration(hours: 5, minutes: 30);

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  /// Carga el usuario desde la API usando el token actual.
  /// Si el token está expirado y keepSession está activo,
  /// intenta refrescarlo antes de consultar /me.
  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        _user = null;
        return;
      }

      // Intentamos refrescar el token proactivamente al iniciar.
      // Si keepSession está activo, esto renueva el token aunque
      // ya haya expirado (siempre que no esté corrompido).
      // Si keepSession es false o el refresh falla, seguimos
      // con el token actual y dejamos que /me determine si sirve.
      await AuthService.tryRefreshToken();

      // Hacemos la petición a /me con el token (nuevo o existente)
      final response = await apiClient.get('/auth-user/me');

      if (response.statusCode == 200) {
        _user = UserModel.fromJson(response.data);
        await AuthService.saveRole(_user!.role);

        // El usuario se autenticó correctamente, activamos el timer
        _startRefreshTimer();
      }
    } catch (e) {
      print('Error cargando perfil: $e');
      _user = null;
      _cancelRefreshTimer();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inicia un timer periódico que refresca el token cada 5.5 horas.
  /// Solo corre mientras el usuario esté autenticado.
  void _startRefreshTimer() {
    _cancelRefreshTimer();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) async {
      print('Timer de refresh: renovando token...');
      final success = await AuthService.tryRefreshToken();
      if (!success) {
        print('Timer de refresh: no se pudo renovar. Cerrando sesión.');
        await logout();
      }
    });
  }

  /// Cancela el timer de refresh si está corriendo.
  void _cancelRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Limpia el estado local, el cache de queries y cierra sesión
  Future<void> logout() async {
    _cancelRefreshTimer();
    queryCache.clear();
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelRefreshTimer();
    super.dispose();
  }
}
