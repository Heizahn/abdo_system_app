// lib/components/client_detail/cards/devices_info_card.dart
import 'package:flutter/material.dart';
import '../shared/detail_info_row.dart';
import '../shared/detail_section_card.dart';

class DevicesInfoData {
  final String? ip;
  final String? sn;
  final String? mac;
  final String? clientType;

  const DevicesInfoData({
    this.ip,
    this.sn,
    this.mac,
    this.clientType,
  });

  bool get hasAnyData =>
      (ip != null && ip!.isNotEmpty) ||
      (sn != null && sn!.isNotEmpty) ||
      (mac != null && mac!.isNotEmpty) ||
      (clientType != null && clientType!.isNotEmpty);
}

class DevicesInfoCard extends StatelessWidget {
  final DevicesInfoData data;

  const DevicesInfoCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    if (data.clientType != null && data.clientType!.isNotEmpty) {
      rows.add(DetailInfoRow(
        icon: Icons.category_rounded,
        label: 'Tipo de conexión',
        value: data.clientType!,
      ));
    }
    if (data.ip != null && data.ip!.isNotEmpty) {
      if (rows.isNotEmpty) rows.add(const DetailRowDivider());
      rows.add(DetailInfoRow(
        icon: Icons.lan_rounded,
        label: 'Dirección IP',
        value: data.ip!,
        copyable: true,
      ));
    }
    if (data.mac != null && data.mac!.isNotEmpty) {
      if (rows.isNotEmpty) rows.add(const DetailRowDivider());
      rows.add(DetailInfoRow(
        icon: Icons.router_rounded,
        label: 'MAC Address',
        value: data.mac!,
        copyable: true,
      ));
    }
    if (data.sn != null && data.sn!.isNotEmpty) {
      if (rows.isNotEmpty) rows.add(const DetailRowDivider());
      rows.add(DetailInfoRow(
        icon: Icons.numbers_rounded,
        label: 'Serial (SN)',
        value: data.sn!,
        copyable: true,
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return DetailSectionCard(
      title: 'Red y Equipos',
      titleIcon: Icons.devices_rounded,
      children: rows,
    );
  }
}
