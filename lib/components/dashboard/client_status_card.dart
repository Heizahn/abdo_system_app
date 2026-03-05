import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/provider_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import 'kpi_card.dart';

class ClientStatusCard extends StatefulWidget {
  const ClientStatusCard({super.key});

  @override
  State<ClientStatusCard> createState() => _ClientStatusCardState();
}

class _ClientStatusCardState extends State<ClientStatusCard>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _lastProviderId;

  int _solventes = 0;
  int _morosos = 0;
  int _suspendidos = 0;

  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _shimmerAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = context.read<ProviderProvider>().selectedProviderId;
      _fetch(id);
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _fetch(String providerId) async {
    setState(() {
      _isLoading = true;
      _lastProviderId = providerId;
    });

    try {
      final response = await apiClient.get(
        '/auth-user/dashboard/solvency',
        queryParameters: providerId != 'all' ? {'owner': providerId} : null,
      );
      final body = response.data as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _solventes = (body['solventes'] as num).toInt();
          _morosos = (body['morosos'] as num).toInt();
          _suspendidos = (body['suspendidos'] as num).toInt();
        });
      }
    } catch (e) {
      debugPrint('Error cargando estado de clientes: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerId = context.watch<ProviderProvider>().selectedProviderId;

    if (providerId != _lastProviderId && !_isLoading) {
      Future.microtask(() => _fetch(providerId));
    }

    if (_isLoading) return _buildSkeleton(context);

    final theme = Theme.of(context);
    final total = _solventes + _morosos + _suspendidos;

    final colorSolventes = theme.extension<AppColors>()!.success;
    final colorMorosos = theme.colorScheme.outline;
    final colorSuspendidos = theme.colorScheme.error;

    return KpiCard(
      title: 'Estado de Clientes',
      icon: Icons.people_alt_rounded,
      iconColor: theme.colorScheme.primary,
      trailing: IconButton(
        onPressed: () => _fetch(providerId),
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
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.1),
                              value: 1,
                              title: '',
                              radius: 24,
                            ),
                          ]
                        : [
                            PieChartSectionData(
                              color: colorSolventes,
                              value: _solventes.toDouble(),
                              title: '',
                              radius: 24,
                            ),
                            PieChartSectionData(
                              color: colorMorosos,
                              value: _morosos.toDouble(),
                              title: '',
                              radius: 24,
                            ),
                            PieChartSectionData(
                              color: colorSuspendidos,
                              value: _suspendidos.toDouble(),
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
                count: _solventes,
                color: colorSolventes,
              ),
              _LegendItem(
                label: 'Morosos',
                count: _morosos,
                color: colorMorosos,
              ),
              _LegendItem(
                label: 'Suspendidos',
                count: _suspendidos,
                color: colorSuspendidos,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, _) {
        final color = theme.colorScheme.onSurface
            .withValues(alpha: _shimmerAnim.value * 0.15);

        return KpiCard(
          title: 'Estado de Clientes',
          icon: Icons.people_alt_rounded,
          iconColor: theme.colorScheme.primary,
          child: Column(
            children: [
              // Circle skeleton
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
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
