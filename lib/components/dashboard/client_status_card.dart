import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/provider_provider.dart';
import '../../services/api_client.dart';
import '../../services/query_cache.dart';
import '../../theme/app_theme.dart';
import '../query_builder.dart';
import 'kpi_card.dart';

/// Datos parseados del endpoint de solvencia.
class _SolvencyData {
  final int solventes;
  final int morosos;
  final int suspendidos;

  const _SolvencyData({
    required this.solventes,
    required this.morosos,
    required this.suspendidos,
  });
}

class ClientStatusCard extends StatelessWidget {
  const ClientStatusCard({super.key});

  static String _queryKey(String providerId) =>
      'dashboard:solvency:$providerId';

  static Future<_SolvencyData> _fetchSolvency(String providerId) async {
    final response = await apiClient.get(
      '/auth-user/dashboard/solvency',
      queryParameters: providerId != 'all' ? {'owner': providerId} : null,
    );
    final body = response.data as Map<String, dynamic>;
    return _SolvencyData(
      solventes: (body['solventes'] as num).toInt(),
      morosos: (body['morosos'] as num).toInt(),
      suspendidos: (body['suspendidos'] as num).toInt(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerId = context.watch<ProviderProvider>().selectedProviderId;

    return QueryBuilder<_SolvencyData>(
      queryKey: _queryKey(providerId),
      queryFn: () => _fetchSolvency(providerId),
      staleTime: const Duration(seconds: 30),
      refetchInterval: const Duration(seconds: 10),
      loading: const _Skeleton(),
      builder: (context, data, isRefreshing) =>
          _Content(data: data, providerId: providerId),
    );
  }
}

// ─── Contenido con datos ────────────────────────────────────────────────────

class _Content extends StatelessWidget {
  final _SolvencyData data;
  final String providerId;

  const _Content({required this.data, required this.providerId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = data.solventes + data.morosos + data.suspendidos;

    final colorSolventes = theme.extension<AppColors>()!.success;
    final colorMorosos = theme.colorScheme.outline;
    final colorSuspendidos = theme.colorScheme.error;

    return KpiCard(
      title: 'Estado de Clientes',
      icon: Icons.people_alt_rounded,
      iconColor: theme.colorScheme.primary,
      trailing: IconButton(
        onPressed: () => queryCache.invalidateQueries(
          'dashboard:solvency',
          showLoading: true,
        ),
        icon: Icon(
          Icons.refresh_rounded,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        tooltip: 'Actualizar',
        style: IconButton.styleFrom(
          minimumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 55,
                    sections: total == 0
                        ? [
                            PieChartSectionData(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                              value: 1,
                              title: '',
                              radius: 24,
                            ),
                          ]
                        : [
                            PieChartSectionData(
                              color: colorSolventes,
                              value: data.solventes.toDouble(),
                              title: '',
                              radius: 24,
                            ),
                            PieChartSectionData(
                              color: colorMorosos,
                              value: data.morosos.toDouble(),
                              title: '',
                              radius: 24,
                            ),
                            PieChartSectionData(
                              color: colorSuspendidos,
                              value: data.suspendidos.toDouble(),
                              title: '',
                              radius: 24,
                            ),
                          ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LegendItem(
                label: 'Solventes',
                count: data.solventes,
                color: colorSolventes,
              ),
              _LegendItem(
                label: 'Morosos',
                count: data.morosos,
                color: colorMorosos,
              ),
              _LegendItem(
                label: 'Suspendidos',
                count: data.suspendidos,
                color: colorSuspendidos,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton ───────────────────────────────────────────────────────────────

class _Skeleton extends StatefulWidget {
  const _Skeleton();

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final color = theme.colorScheme.onSurface.withValues(
          alpha: _anim.value * 0.15,
        );

        return KpiCard(
          title: 'Estado de Clientes',
          icon: Icons.people_alt_rounded,
          iconColor: theme.colorScheme.primary,
          child: Column(
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _skelBox(color, width: 70, height: 32),
                  _skelBox(color, width: 70, height: 32),
                  _skelBox(color, width: 70, height: 32),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _skelBox(Color color, {double? width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ─── Legend item ────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
