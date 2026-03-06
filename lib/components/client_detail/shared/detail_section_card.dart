// lib/components/client_detail/shared/detail_section_card.dart
import 'package:flutter/material.dart';

/// Contenedor tipo "Paper" con título de sección y lista de filas.
/// Equivalente al Paper/Box de cada sub-sección en la web.
class DetailSectionCard extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final List<Widget> children;

  const DetailSectionCard({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Título de sección ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Row(
            children: [
              Icon(titleIcon, size: 15, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        // ── Tarjeta ────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.brightness == Brightness.light
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.10)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}
