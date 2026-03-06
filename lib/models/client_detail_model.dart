// lib/models/client_detail_model.dart
import 'client_model.dart'; // Reutilizamos ClientStatus

class ClientDetail {
  final String id;
  final String name;
  final String dni;
  final String phone;
  final String? email;
  final ClientStatus status;
  final double balance;
  // Plan
  final String planName;
  final double planPrice;
  final double planMbps;
  final double paymentDay;
  // Ubicación
  final String sectorName;
  final String address;
  final String? gps;
  // Red / Dispositivo
  final String? ip;
  final String? sn;
  final String? mac;
  final String? clientType;
  // Auditoría
  final String? commentary;
  final String? creator;
  final String? editor;
  final String? suspender;
  final String? createdAt;
  final String? suspendedAt;
  final String? updatedAt;
  final String? installedAt;
  // Extras
  final int? providerTag;
  final bool? isSuspendable;

  const ClientDetail({
    required this.id,
    required this.name,
    required this.dni,
    required this.phone,
    this.email,
    required this.status,
    required this.balance,
    required this.planName,
    required this.planPrice,
    required this.planMbps,
    required this.paymentDay,
    required this.sectorName,
    required this.address,
    this.gps,
    this.ip,
    this.sn,
    this.mac,
    this.clientType,
    this.commentary,
    this.creator,
    this.editor,
    this.suspender,
    this.createdAt,
    this.suspendedAt,
    this.updatedAt,
    this.installedAt,
    this.providerTag,
    this.isSuspendable,
  });

  factory ClientDetail.fromJson(Map<String, dynamic> json) {
    return ClientDetail(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      dni: (json['dni'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      email: json['email'] as String?,
      status: ClientStatus.fromString((json['status'] as String?) ?? ''),
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      planName: (json['plan_name'] as String?) ?? '',
      planPrice: (json['plan_price'] as num?)?.toDouble() ?? 0.0,
      planMbps: (json['plan_mbps'] as num?)?.toDouble() ?? 0.0,
      paymentDay: (json['payment'] as num?)?.toDouble() ?? 0.0,
      sectorName: (json['sector_name'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      gps: json['gps'] as String?,
      ip: json['ip'] as String?,
      sn: json['sn'] as String?,
      mac: json['mac'] as String?,
      clientType: json['client_type'] as String?,
      commentary: json['commentary'] as String?,
      creator: json['creator'] as String?,
      editor: json['editor'] as String?,
      suspender: json['suspender'] as String?,
      createdAt: json['created_at'] as String?,
      suspendedAt: json['suspended_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      installedAt: json['installed_at'] as String?,
      providerTag: (json['provider_tag'] as num?)?.toInt(),
      isSuspendable: json['is_suspendable'] as bool?,
    );
  }
}
