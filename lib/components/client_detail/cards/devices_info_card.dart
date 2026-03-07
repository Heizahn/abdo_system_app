// lib/components/client_detail/cards/devices_info_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shared/detail_info_row.dart';
import '../shared/detail_section_card.dart';

class DevicesInfoData {
  final String? ip;
  final String? ipPppoe;
  final String? sn;
  final String? mac;
  final String? clientType;

  const DevicesInfoData({
    this.ip,
    this.ipPppoe,
    this.sn,
    this.mac,
    this.clientType,
  });

  bool get hasAnyData =>
      (ip != null && ip!.isNotEmpty) ||
      (ipPppoe != null && ipPppoe!.isNotEmpty) ||
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
    final hasPppoe = data.ipPppoe != null && data.ipPppoe!.isNotEmpty;
    final hasIp    = data.ip != null && data.ip!.isNotEmpty;

    if (hasPppoe || hasIp) {
      if (rows.isNotEmpty) rows.add(const DetailRowDivider());
      rows.add(_IpRow(
        ip: hasPppoe ? data.ipPppoe! : data.ip!,
        isPppoe: hasPppoe,
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

// ─── Fila de IP con badge PPPoE ───────────────────────────────────────────────

class _IpRow extends StatelessWidget {
  final String ip;
  final bool isPppoe;

  const _IpRow({required this.ip, required this.isPppoe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.lan_rounded,
              size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Dirección IP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isPppoe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'Online · PPPoE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  ip,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy_rounded,
                size: 16, color: theme.colorScheme.onSurfaceVariant),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: ip));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('IP copiada'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
