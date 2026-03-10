import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/provider_provider.dart';
import '../../services/api_client.dart';
import '../../services/query_cache.dart';
import 'kpi_card.dart';

/// Datos parseados del endpoint de cierre mensual.
class _ClosingData {
  final List<String> months;
  final String selectedMonth;
  final double collected;
  final double pending;
  final double? efficiency;
  final bool noData;

  const _ClosingData({
    required this.months,
    required this.selectedMonth,
    required this.collected,
    required this.pending,
    required this.efficiency,
    this.noData = false,
  });
}

class MonthlyClosingCard extends StatefulWidget {
  const MonthlyClosingCard({super.key});

  @override
  State<MonthlyClosingCard> createState() => _MonthlyClosingCardState();
}

class _MonthlyClosingCardState extends State<MonthlyClosingCard> {
  String? _selectedMonth;
  List<String> _cachedMonths = [];

  String _queryKey(String providerId, {String? month}) {
    final base = 'dashboard:monthly-closing:$providerId';
    return month != null ? '$base:$month' : base;
  }

  Future<_ClosingData> _fetchClosing(String providerId, {String? month}) async {
    final params = <String, dynamic>{};
    if (month != null) params['month'] = month;
    if (providerId != 'all') params['owner'] = providerId;

    try {
      final response = await apiClient.get(
        '/auth-user/dashboard/monthly-closing',
        queryParameters: params.isNotEmpty ? params : null,
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;

      return _ClosingData(
        months: List<String>.from(body['months'] as List),
        selectedMonth: body['selected_month'] as String,
        collected: (data['collected'] as num).toDouble(),
        pending: (data['pending'] as num).toDouble(),
        efficiency: data['efficiency'] != null
            ? (data['efficiency'] as num).toDouble()
            : null,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _ClosingData(
          months: _cachedMonths,
          selectedMonth: month ?? '',
          collected: 0,
          pending: 0,
          efficiency: null,
          noData: true,
        );
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerId = context.watch<ProviderProvider>().selectedProviderId;
    final key = _queryKey(providerId, month: _selectedMonth);

    final cachedData = queryCache.getData<_ClosingData>(key);
    final isFresh = queryCache.isFresh(key, const Duration(seconds: 30));

    // Si hay datos en cache, mostrarlos directamente
    if (cachedData != null) {
      // Actualizar lista de meses cacheada
      if (cachedData.months.isNotEmpty) {
        _cachedMonths = cachedData.months;
      }

      // Re-fetch en background si los datos están stale
      if (!isFresh) {
        _refetchInBackground(providerId);
      }

      return cachedData.noData
          ? _buildNoData(context, cachedData)
          : _buildContent(context, cachedData, providerId);
    }

    // Primera carga: fetch y mostrar skeleton
    _refetchInBackground(providerId);
    return const _Skeleton();
  }

  void _refetchInBackground(String providerId) {
    final key = _queryKey(providerId, month: _selectedMonth);
    if (queryCache.isFetching(key)) return;

    queryCache
        .fetch<_ClosingData>(
          queryKey: key,
          queryFn: () => _fetchClosing(providerId, month: _selectedMonth),
          forceRefresh: true,
        )
        .then((data) {
          if (mounted && data.months.isNotEmpty) {
            setState(() => _cachedMonths = data.months);
          }
        })
        .catchError((e) {
          debugPrint('Error cargando cierre mensual: $e');
        });
  }

  void _onMonthSelected(String month, String providerId) {
    setState(() => _selectedMonth = month);
    final key = _queryKey(providerId, month: month);
    queryCache
        .fetch<_ClosingData>(
          queryKey: key,
          queryFn: () => _fetchClosing(providerId, month: month),
          forceRefresh: true,
        )
        .then((_) {
          if (mounted) setState(() {});
        })
        .catchError((e) {
          debugPrint('Error cargando cierre mensual: $e');
        });
  }

  // ─── Builders ──────────────────────────────────────────────────────────

  Widget _buildContent(
    BuildContext context,
    _ClosingData data,
    String providerId,
  ) {
    final theme = Theme.of(context);
    final colorUsd = theme.colorScheme.primary;
    final colorVes = theme.colorScheme.secondary;
    final trailing = data.months.isNotEmpty
        ? _buildMonthDropdown(theme, providerId)
        : null;

    final total = data.collected + data.pending;
    final collectedFlex = total > 0
        ? (data.collected / total * 100).round().clamp(1, 99)
        : 100;
    final pendingFlex = total > 0 ? 100 - collectedFlex : 0;

    final efficiencyLabel = data.efficiency == null
        ? '100'
        : data.efficiency!.toStringAsFixed(2);

    return KpiCard(
      title: 'Cierre Mensual',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: Colors.tealAccent.shade400,
      trailing: trailing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECAUDADO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${data.collected.toStringAsFixed(2)}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$efficiencyLabel%',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Eficiencia de Cobro', style: theme.textTheme.bodySmall),
              Text(
                '\$${total.toStringAsFixed(2)} Total',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Expanded(
                  flex: collectedFlex,
                  child: Container(height: 12, color: colorUsd),
                ),
                if (pendingFlex > 0)
                  Expanded(
                    flex: pendingFlex,
                    child: Container(height: 12, color: colorVes),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegend(
                'Ingresado  \$${data.collected.toStringAsFixed(2)}',
                colorUsd,
              ),
              _buildLegend(
                'Pendiente  \$${data.pending.toStringAsFixed(2)}',
                colorVes,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoData(BuildContext context, _ClosingData data) {
    final theme = Theme.of(context);
    final providerId = context.read<ProviderProvider>().selectedProviderId;
    final trailing = _cachedMonths.isNotEmpty
        ? _buildMonthDropdown(theme, providerId)
        : null;

    return KpiCard(
      title: 'Cierre Mensual',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: Colors.tealAccent.shade400,
      trailing: trailing,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sin datos para este mes',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthDropdown(ThemeData theme, String providerId) {
    return Builder(
      builder: (ctx) => InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _openMonthMenu(ctx, theme, providerId),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedMonth ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMonthMenu(
    BuildContext ctx,
    ThemeData theme,
    String providerId,
  ) async {
    final box = ctx.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(ctx).overlay!.context.findRenderObject()! as RenderBox;

    final btnRect = Rect.fromPoints(
      box.localToGlobal(Offset.zero, ancestor: overlay),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
    );
    final screenH = overlay.size.height;
    final screenW = overlay.size.width;

    final spaceBelow = screenH - btnRect.bottom;
    final spaceAbove = btnRect.top;

    final RelativeRect position;
    if (spaceAbove > spaceBelow) {
      position = RelativeRect.fromLTRB(
        btnRect.left,
        0,
        screenW - btnRect.right,
        screenH - btnRect.top,
      );
    } else {
      position = RelativeRect.fromLTRB(
        btnRect.left,
        btnRect.bottom,
        screenW - btnRect.right,
        0,
      );
    }

    final selected = await showMenu<String>(
      context: ctx,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      items: _cachedMonths
          .map(
            (m) => PopupMenuItem<String>(
              value: m,
              child: Text(
                m,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: m == _selectedMonth
                      ? FontWeight.w700
                      : FontWeight.normal,
                  color: m == _selectedMonth ? theme.colorScheme.primary : null,
                ),
              ),
            ),
          )
          .toList(),
    );

    if (selected != null && selected != _selectedMonth) {
      _onMonthSelected(selected, providerId);
    }
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
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
          title: 'Cierre Mensual',
          icon: Icons.account_balance_wallet_rounded,
          iconColor: Colors.tealAccent.shade400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _skelBox(color, width: 90, height: 11),
              const SizedBox(height: 8),
              _skelBox(color, width: 180, height: 36),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _skelBox(color, width: 110, height: 12),
                  _skelBox(color, width: 90, height: 12),
                ],
              ),
              const SizedBox(height: 10),
              _skelBox(color, height: 12),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _skelBox(color, width: 100, height: 12),
                  _skelBox(color, width: 100, height: 12),
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
