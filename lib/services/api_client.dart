// lib/services/api_client.dart
import 'package:dio/dio.dart';
import 'package:abdo_system_app/config/env_config.dart';
import 'package:abdo_system_app/services/auth_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;

  factory ApiClient() => _instance;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          final path = e.requestOptions.path;
          final isAuthRoute =
              path.contains('/login') || path.contains('/refresh-token');

          if (e.response?.statusCode == 401 && !isAuthRoute) {
            // 1. Verificamos si el usuario quiso mantener la sesión
            final keepSession = await AuthService.getKeepSession();

            if (keepSession) {
              print(
                '🔄 Token vencido y "Mantener Sesión" activo. Refrescando...',
              );

              // Usamos el token actual como pediste
              final currentToken = await AuthService.getToken();

              if (currentToken != null) {
                try {
                  final refreshDio = Dio(
                    BaseOptions(baseUrl: EnvConfig.apiUrl),
                  );

                  // 2. POST a /refresh-token mandando el token actual en el body
                  final refreshResponse = await refreshDio.post(
                    '/auth-user/refresh-token',
                    data: {'token': currentToken},
                  );

                  // 3. Extraer y guardar el nuevo token
                  final newToken = refreshResponse.data['token'];
                  await AuthService.saveTokens(token: newToken);
                  print('✅ Token refrescado exitosamente.');

                  // 4. Reintentar la petición original con el nuevo token
                  final options = e.requestOptions;
                  options.headers['Authorization'] = 'Bearer $newToken';
                  final cloneReq = await dio.fetch(options);
                  return handler.resolve(cloneReq);
                } catch (refreshError) {
                  print('❌ Error al refrescar. Expiró o es inválido.');
                  await AuthService.logout();
                  return handler.next(e);
                }
              }
            } else {
              // Si no marcó "Mantener sesión", lo deslogueamos de inmediato
              print(
                '❌ Token expirado y "Mantener Sesión" es false. Cerrando sesión.',
              );
              await AuthService.logout();
              // Aquí el enrutador / la UI lo devolverá al login
            }
          }

          // Pasamos el error para que la UI lo maneje (ej. credenciales inválidas en login)
          return handler.next(e);
        },
      ),
    );

    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
}

final apiClient = ApiClient().dio;
