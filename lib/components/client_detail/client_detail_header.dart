// lib/components/client_detail/client_detail_header.dart
import 'package:flutter/material.dart';
import '../../models/client_model.dart';
import '../../models/client_detail_model.dart';
import '../../theme/app_theme.dart';

class ClientDetailHeader extends StatelessWidget {
  final ClientDetail client;

  const ClientDetailHeader({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context, client.status);
    final statusLabel = _statusLabel(client.status);
    final balanceColor = client.balance < 0
        ? theme.colorScheme.error
        : theme.extension<AppColors>()!.success;
    final initial = client.name.isNotEmpty ? client.name[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.brightness == Brightness.light
                ? theme.colorScheme.onSurface.withValues(alpha: 0.10)
                : theme.colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + nombre + estado + saldo ──────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chip de proveedor si existe
                    if (client.providerTag != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.device_hub_rounded,
                                size: 12,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'ABDO77-${client.providerTag}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      client.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.account_balance_wallet_rounded,
                            size: 14, color: balanceColor),
                        const SizedBox(width: 4),
                        Text(
                          '\$${client.balance.toStringAsFixed(2)}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: balanceColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Botones de acción ─────────────────────────────────────────
          _ActionButtons(client: client),
        ],
      ),
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

// ─── Botones de acción ────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final ClientDetail client;

  const _ActionButtons({required this.client});

  @override
  Widget build(BuildContext context) {
    final isSuspendido = client.status == ClientStatus.suspendido;
    final isRetirado   = client.status == ClientStatus.retirado;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Suspender  → visible si NO está suspendido ni retirado
        // Activar    → visible si está suspendido
        if (!isRetirado)
          _ActionButton(
            label: isSuspendido ? 'Activar' : 'Suspender',
            icon: isSuspendido
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            variant: isSuspendido
                ? _ButtonVariant.success
                : _ButtonVariant.warning,
            onPressed: () {
              // TODO: implementar suspensión / activación
            },
          ),

        // Retirar → SOLO si está suspendido
        if (isSuspendido)
          _ActionButton(
            label: 'Retirar',
            icon: Icons.logout_rounded,
            variant: _ButtonVariant.error,
            onPressed: () {
              // TODO: implementar retiro
            },
          ),
      ],
    );
  }
}

enum _ButtonVariant { outlined, success, warning, error }

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final _ButtonVariant variant;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.variant,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = switch (variant) {
      _ButtonVariant.outlined => theme.colorScheme.primary,
      _ButtonVariant.success  => theme.extension<AppColors>()!.success,
      _ButtonVariant.warning  => theme.colorScheme.tertiary,
      _ButtonVariant.error    => theme.colorScheme.error,
    };

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        backgroundColor: color.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
