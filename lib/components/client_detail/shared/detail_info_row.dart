// lib/components/client_detail/shared/detail_info_row.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fila de información reutilizable: icono + label + valor.
/// Si [copyable] es true, al tocar copia el valor al portapapeles.
class DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  const DetailInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: copyable && value.isNotEmpty && value != '—'
          ? () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copiado'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isEmpty ? '—' : value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (copyable && value.isNotEmpty && value != '—')
              Icon(
                Icons.copy_rounded,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
              ),
          ],
        ),
      ),
    );
  }
}

/// Divisor interno entre filas de una sección.
class DetailRowDivider extends StatelessWidget {
  const DetailRowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 48,
      endIndent: 16,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
    );
  }
}
