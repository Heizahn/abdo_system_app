import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // Inicialización y validación
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");

    // Lista de variables obligatorias
    const requiredVars = ['API_URL'];

    for (var variable in requiredVars) {
      if (dotenv.env[variable] == null || dotenv.env[variable]!.isEmpty) {
        throw Exception(
          '❌ ERROR DE CONFIGURACIÓN: La variable de entorno "$variable" no está definida en el archivo .env',
        );
      }
    }
  }

  // Getters tipados para evitar usar strings en el resto del código
  static String get apiUrl => dotenv.env['API_URL']!;

  // Ejemplo para futuras variables (como un SENTRY_DSN o API_KEY)
  static String get environment => dotenv.env['NODE_ENV'] ?? 'development';
}
