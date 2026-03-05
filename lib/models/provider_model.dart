// lib/models/provider_model.dart

class ProviderModel {
  final String id;
  final String tag;
  final String name;

  ProviderModel({
    required this.id,
    required this.tag,
    required this.name,
  });

  // Método mágico para convertir el JSON de Rust a tu Objeto Dart
  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'] ?? '',
      tag: json['tag'] ?? 'Sin Tag'.toUpperCase(),
      name: json['name'] ?? 'Desconocido'.toUpperCase(),
    );
  }
}