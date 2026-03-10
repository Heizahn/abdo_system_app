// lib/components/clients/client_card.dart
import 'package:flutter/material.dart';
import '../../models/client_model.dart';
import '../../theme/app_theme.dart';

class ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback? onTap;

  /// Tokens de búsqueda normalizados para resaltar coincidencias.
  /// Si está vacío no se resalta nada.
  final List<String> highlightTokens;

  const ClientCard({
    super.key,
    required this.client,
    this.onTap,
    this.highlightTokens = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context, client.status);
    final statusLabel = _statusLabel(client.status);

    final borderColor = theme.brightness == Brightness.light
        ? theme.colorScheme.onSurface.withValues(alpha: 0.10)
        : theme.colorScheme.onSurface.withValues(alpha: 0.06);

    return RepaintBoundary(
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Avatar(name: client.name, color: statusColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Nombre + badge de estado ──────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _HighlightText(
                              text: client.name,
                              tokens: highlightTokens,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              highlightColor: theme.colorScheme.primary,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(label: statusLabel, color: statusColor),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // ── Plan + Sector ──────────────────────────────────────
                      Row(
                        children: [
                          Icon(
                            Icons.wifi_rounded,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              client.planName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: _HighlightText(
                              text: client.sectorName,
                              tokens: highlightTokens,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              highlightColor: theme.colorScheme.primary,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // ── Saldo ──────────────────────────────────────────────
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 12,
                            color: client.balance < 0
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Saldo: \$${client.balance.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: client.balance < 0
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: client.balance < 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, ClientStatus status) {
    final theme = Theme.of(context);
    switch (status) {
      case ClientStatus.solvente:
        return theme.extension<AppColors>()!.success;
      case ClientStatus.moroso:
        return theme.colorScheme.outline;
      case ClientStatus.suspendido:
        return theme.colorScheme.error;
      case ClientStatus.retirado:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _statusLabel(ClientStatus status) {
    switch (status) {
      case ClientStatus.solvente:
        return 'Solvente';
      case ClientStatus.moroso:
        return 'Moroso';
      case ClientStatus.suspendido:
        return 'Suspendido';
      case ClientStatus.retirado:
        return 'Retirado';
    }
  }
}

// ─── Resaltado de texto ───────────────────────────────────────────────────────

/// Renderiza [text] resaltando con [highlightColor] las partes que
/// coincidan con cualquiera de los [tokens] (comparación sin tildes).
class _HighlightText extends StatelessWidget {
  final String text;
  final List<String> tokens;
  final TextStyle? style;
  final Color highlightColor;
  final int maxLines;

  const _HighlightText({
    required this.text,
    required this.tokens,
    required this.highlightColor,
    this.style,
    this.maxLines = 1,
  });

  /// Elimina tildes para la comparación.
  static String _norm(String s) {
    const accents = 'áéíóúüñÁÉÍÓÚÜÑ';
    const plain = 'aeiouunAEIOUUN';
    return s.split('').map((c) {
      final i = accents.indexOf(c);
      return i >= 0 ? plain[i] : c;
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    if (tokens.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Construir regex que une todos los tokens con OR, sin tildes
    final pattern = tokens.map((t) => RegExp.escape(t)).join('|');
    final regex = RegExp(pattern, caseSensitive: false);

    final normalizedText = _norm(text);
    final spans = <TextSpan>[];
    int cursor = 0;

    for (final match in regex.allMatches(normalizedText)) {
      // Texto antes del match (original, sin normalizar)
      if (match.start > cursor) {
        spans.add(
          TextSpan(text: text.substring(cursor, match.start), style: style),
        );
      }
      // Texto coincidente resaltado (tomamos del original para preservar tildes)
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style:
              style?.copyWith(
                color: highlightColor,
                fontWeight: FontWeight.w800,
                backgroundColor: highlightColor.withValues(alpha: 0.12),
              ) ??
              TextStyle(
                color: highlightColor,
                fontWeight: FontWeight.w800,
                backgroundColor: highlightColor.withValues(alpha: 0.12),
              ),
        ),
      );
      cursor = match.end;
    }

    // Resto del texto sin coincidencias
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: style));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ─── Widgets privados ────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final Color color;

  const _Avatar({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
