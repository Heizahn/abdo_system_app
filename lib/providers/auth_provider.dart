import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

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

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  /// Carga el usuario desde la API usando el token actual
  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners(); // Avisa a la UI que estamos cargando

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        _user = null;
        return;
      }

      // Hacemos la petición a /me
      final response = await apiClient.get('/auth-user/me');
      
      if (response.statusCode == 200) {
        _user = UserModel.fromJson(response.data);
        // Guardamos el rol en el Secure Storage para que el Router lo use rápido
        await AuthService.saveRole(_user!.role); 
      }
    } catch (e) {
      print('Error cargando perfil: $e');
      _user = null;
      // Si falla por 401, el interceptor de Dio ya intentará hacer refresh,
      // pero si el refresh falla, el interceptor hará logout y borrará el token.
    } finally {
      _isLoading = false;
      notifyListeners(); // Avisa a la UI que ya terminamos (con o sin usuario)
    }
  }

  /// Limpia el estado local y cierra sesión
  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }
}