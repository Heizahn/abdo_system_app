// lib/router/app_router.dart
import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/client_detail_screen.dart';
import '../layouts/main_layout.dart';
import '../screens/not_found_screen.dart';
import '../services/auth_service.dart';
import '../config/roles.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    errorBuilder: (context, state) =>
        NotFoundScreen(path: state.uri.toString()),

    // REDIRECCIÓN GLOBAL Y PROTECCIÓN DE RUTAS
    redirect: (context, state) async {
      final bool loggedIn = await AuthService.getToken() != null;
      final bool loggingIn = state.matchedLocation == '/login';
      final bool isRoot =
          state.matchedLocation == '/'; // 🔥 NUEVO: Detectar la raíz

      // 1. Si no está autenticado, expulsar al login
      if (!loggedIn) {
        return loggingIn ? null : '/login';
      }

      // 2. Obtener el rol del usuario
      final userRole = await AuthService.getUserRole();

      // Si por alguna razón hay token pero no hay rol (data corrupta), forzar login
      if (userRole == null) {
        await AuthService.logout();
        return '/login';
      }

      // 3. Lógica de DefaultRedirect (Si intenta ir al login o a la raíz '/' estando logueado)
      if (loggingIn || isRoot) {
        // 🔥 MODIFICADO: Agregamos isRoot aquí
        return _getDefaultRoute(userRole);
      }

      // 4. Lógica de ProtectedRouter (Verificar si tiene acceso a la ruta solicitada)
      if (!_hasRoleAccess(userRole, state.matchedLocation)) {
        // Si no tiene acceso, lo mandamos a su ruta por defecto
        return _getDefaultRoute(userRole);
      }

      // Permitir el paso
      return null;
    },

    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/home'),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainLayout(initialIndex: 0),
      ),
      GoRoute(
        path: '/clients',
        builder: (context, state) => const MainLayout(initialIndex: 1),
      ),
      GoRoute(
        path: '/client/:id',
        builder: (context, state) => ClientDetailScreen(
          clientId: state.pathParameters['id']!,
        ),
      ),
    ],
  );

  // --- MÉTODOS PRIVADOS DE AYUDA ---

  /// Equivalente a tu componente DefaultRedirect de React
  static String _getDefaultRoute(double role) {
    switch (role) {
      case Roles.paymentUser:
      case Roles.operator:
      case Roles.accountant:
      case Roles.messengerAccountant:
        return '/clients';
      case Roles.superadmin:
      case Roles.provider:
      default:
        return '/home';
    }
  }

  /// Equivalente a la función hasRoleAccess de tu ProtectedRouter
  static bool _hasRoleAccess(double role, String currentPath) {
    final allowedRoutes = roleRoutes[role] ?? [];

    // Acceso total
    if (allowedRoutes.contains('*')) return true;

    // Verificamos si la ruta actual coincide exactamente o si es una subruta (ej: /client/123)
    return allowedRoutes.any((route) {
      return currentPath == route || currentPath.startsWith('$route/');
    });
  }
}
