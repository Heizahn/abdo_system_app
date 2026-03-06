// lib/components/client_detail/cards/status_info_card.dart
import 'package:flutter/material.dart';
import '../../../models/client_model.dart';
import '../../../theme/app_theme.dart';
import '../shared/detail_info_row.dart';
import '../shared/detail_section_card.dart';

class StatusInfoData {
  final ClientStatus status;
  final double balance;
  final String? creator;
  final String? editor;
  final String? suspender;
  final String? createdAt;
  final String? suspendedAt;
  final String? installedAt;
  final int? providerTag;

  const StatusInfoData({
    required this.status,
    required this.balance,
    this.creator,
    this.editor,
    this.suspender,
    this.createdAt,
    this.suspendedAt,
    this.installedAt,
    this.providerTag,
  });
}

class StatusInfoCard extends StatelessWidget {
  final StatusInfoData data;

  const StatusInfoCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context, data.status);
    final statusLabel = _statusLabel(data.status);
    final balanceColor = data.balance < 0
        ? theme.colorScheme.error
        : theme.extension<AppColors>()!.success;

    return DetailSectionCard(
      title: 'Estado y Auditoría',
      titleIcon: Icons.info_outline_rounded,
      children: [
        // Estado con badge
        _StatusRow(label: statusLabel, color: statusColor, theme: theme),
        const DetailRowDivider(),
        // Saldo
        _BalanceRow(balance: data.balance, color: balanceColor, theme: theme),

        if (data.providerTag != null) ...[
          const DetailRowDivider(),
          DetailInfoRow(
            icon: Icons.device_hub_rounded,
            label: 'Proveedor',
            value: 'ABDO77-${data.providerTag}',
          ),
        ],
        if (data.creator != null && data.creator!.isNotEmpty) ...[
          const DetailRowDivider(),
          DetailInfoRow(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Creado por',
            value: data.creator!,
          ),
        ],
        if (data.createdAt != null && data.createdAt!.isNotEmpty) ...[
          const DetailRowDivider(),
          DetailInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Fecha de creación',
            value: data.createdAt!,
          ),
        ],
        if (data.installedAt != null && data.installedAt!.isNotEmpty) ...[
          const DetailRowDivider(),
          DetailInfoRow(
            icon: Icons.build_rounded,
            label: 'Fecha de instalación',
            value: data.installedAt!,
          ),
        ],
        if (data.editor != null && data.editor!.isNotEmpty) ...[
          const DetailRowDivider(),
          DetailInfoRow(
            icon: Icons.edit_rounded,
            label: 'Editado por',
            value: data.editor!,
          ),
        ],
        if (data.suspender != null && data.suspender!.isNotEmpty) ...[
          const DetailRowDivider(),
          DetailInfoRow(
            icon: Icons.pause_circle_outline_rounded,
            label: 'Suspendido por',
            value: data.suspender!,
          ),
        ],
        if (data.suspendedAt != null && data.suspendedAt!.isNotEmpty) ...[
          const DetailRowDivider(),
          DetailInfoRow(
            icon: Icons.event_busy_rounded,
            label: 'Fecha de suspensión',
            value: data.suspendedAt!,
          ),
        ],
      ],
    );
  }

  Color _statusColor(BuildContext context, ClientStatus status) {
    final theme = Theme.of(context);
    switch (status) {
      case ClientStatus.solvente:   return theme.extension<AppColors>()!.success;
      case ClientStatus.moroso:     return theme.colorScheme.outline;
      case ClientStatus.suspendido: return theme.colorScheme.error;
      case ClientStatus.retirado:   return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _statusLabel(ClientStatus status) {
    switch (status) {
      case ClientStatus.solvente:   return 'Solvente';
      case ClientStatus.moroso:     return 'Moroso';
      case ClientStatus.suspendido: return 'Suspendido';
      case ClientStatus.retirado:   return 'Retirado';
    }
  }
}

// ─── Filas especiales con color ───────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  final String label;
  final Color color;
  final ThemeData theme;

  const _StatusRow({required this.label, required this.color, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(Icons.circle_rounded, size: 18, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estado',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.3,
                    )),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final double balance;
  final Color color;
  final ThemeData theme;

  const _BalanceRow({required this.balance, required this.color, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_rounded, size: 18, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saldo actual',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.3,
                    )),
                const SizedBox(height: 2),
                Text('\$${balance.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
