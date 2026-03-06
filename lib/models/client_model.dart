// lib/models/client_model.dart

enum ClientStatus {
  solvente,
  moroso,
  suspendido,
  retirado;

  static ClientStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'solvente':   return ClientStatus.solvente;
      case 'moroso':     return ClientStatus.moroso;
      case 'suspendido': return ClientStatus.suspendido;
      case 'retirado':   return ClientStatus.retirado;
      default:           return ClientStatus.solvente;
    }
  }
}

class Client {
  final String id;
  final String name;
  final String dni;
  final String phone;
  final String sectorName;
  final ClientStatus status;
  final double balance;
  final String planName;
  final double planPrice;

  const Client({
    required this.id,
    required this.name,
    required this.dni,
    required this.phone,
    required this.sectorName,
    required this.status,
    required this.balance,
    required this.planName,
    required this.planPrice,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      dni: (json['dni'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      sectorName: (json['sector_name'] as String?) ?? '',
      status: ClientStatus.fromString((json['status'] as String?) ?? ''),
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      planName: (json['plan_name'] as String?) ?? '',
      planPrice: (json['plan_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

}
