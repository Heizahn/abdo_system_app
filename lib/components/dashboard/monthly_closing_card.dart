import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/provider_provider.dart';
import '../../services/api_client.dart';
import 'kpi_card.dart';

class MonthlyClosingCard extends StatefulWidget {
  const MonthlyClosingCard({super.key});

  @override
  State<MonthlyClosingCard> createState() => _MonthlyClosingCardState();
}

class _MonthlyClosingCardState extends State<MonthlyClosingCard>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _noData = false;
  String? _lastProviderId;

  List<String> _months = [];
  String? _selectedMonth;
  double _collected = 0;
  double _pending = 0;
  double? _efficiency;

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

  Future<void> _fetch(String providerId, {String? month}) async {
    setState(() {
      _isLoading = true;
      _lastProviderId = providerId;
    });

    try {
      final params = <String, dynamic>{};
      if (month != null) params['month'] = month;
      if (providerId != 'all') params['owner'] = providerId;

      final response = await apiClient.get(
        '/auth-user/dashboard/monthly-closing',
        queryParameters: params.isNotEmpty ? params : null,
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _noData = false;
          _months = List<String>.from(body['months'] as List);
          _selectedMonth = body['selected_month'] as String;
          _collected = (data['collected'] as num).toDouble();
          _pending = (data['pending'] as num).toDouble();
          _efficiency =
              data['efficiency'] != null
                  ? (data['efficiency'] as num).toDouble()
                  : null;
        });
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 && mounted) {
        setState(() {
          _noData = true;
          // Preserve _months from prior fetch; just update selected month
          if (month != null) _selectedMonth = month;
        });
      } else {
        debugPrint('Error cargando cierre mensual: $e');
      }
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
    final colorUsd = theme.colorScheme.primary;
    final colorVes = theme.colorScheme.secondary;
    final trailing = _months.isNotEmpty ? _buildMonthDropdown(theme) : null;

    if (_noData) {
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
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
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

    final total = _collected + _pending;
    final collectedFlex =
        total > 0 ? (_collected / total * 100).round().clamp(1, 99) : 100;
    final pendingFlex = total > 0 ? 100 - collectedFlex : 0;

    // efficiency ya es un porcentaje (ej. 0.05 = 0.05%), null = 100%
    final efficiencyLabel =
        _efficiency == null ? '100' : _efficiency!.toStringAsFixed(2);

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
                '\$${_collected.toStringAsFixed(2)}',
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
              _buildLegend('Ingresado  \$${_collected.toStringAsFixed(2)}', colorUsd),
              _buildLegend('Pendiente  \$${_pending.toStringAsFixed(2)}', colorVes),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthDropdown(ThemeData theme) {
    return Builder(
      builder: (ctx) => InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _openMonthMenu(ctx, theme),
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

  Future<void> _openMonthMenu(BuildContext ctx, ThemeData theme) async {
    final providerId = context.read<ProviderProvider>().selectedProviderId;
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

    // Prefer downward; open upward only when more space is above
    final RelativeRect position;
    if (spaceAbove > spaceBelow) {
      // Anchor at top of button → menu expands upward
      position = RelativeRect.fromLTRB(
        btnRect.left,
        0,
        screenW - btnRect.right,
        screenH - btnRect.top,
      );
    } else {
      // Anchor at bottom of button → menu expands downward
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
      items: _months
          .map(
            (m) => PopupMenuItem<String>(
              value: m,
              child: Text(
                m,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      m == _selectedMonth ? FontWeight.w700 : FontWeight.normal,
                  color:
                      m == _selectedMonth
                          ? theme.colorScheme.primary
                          : null,
                ),
              ),
            ),
          )
          .toList(),
    );

    if (selected != null && selected != _selectedMonth) {
      _fetch(providerId, month: selected);
    }
  }

  Widget _buildSkeleton(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, _) {
        final color = theme.colorScheme.onSurface.withValues(alpha: _shimmerAnim.value * 0.15);

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
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
