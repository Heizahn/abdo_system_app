import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/provider_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import 'kpi_card.dart';

class _Payment {
  final String id;
  final DateTime createdAt;
  final String reason;
  final String state;
  final double amount;
  final String clientName;

  const _Payment({
    required this.id,
    required this.createdAt,
    required this.reason,
    required this.state,
    required this.amount,
    required this.clientName,
  });

  factory _Payment.fromJson(Map<String, dynamic> json) => _Payment(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        reason: json['reason'] as String,
        state: json['state'] as String,
        amount: (json['amount'] as num).toDouble(),
        clientName: json['client_name'] as String,
      );
}

class LatestPaymentsCard extends StatefulWidget {
  const LatestPaymentsCard({super.key});

  @override
  State<LatestPaymentsCard> createState() => _LatestPaymentsCardState();
}

class _LatestPaymentsCardState extends State<LatestPaymentsCard>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _lastProviderId;
  List<_Payment> _payments = [];

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
        '/auth-user/dashboard/latest-payments',
        queryParameters: providerId != 'all' ? {'owner': providerId} : null,
      );
      final list = response.data as List<dynamic>;

      if (mounted) {
        setState(() {
          _payments =
              list.map((e) => _Payment.fromJson(e as Map<String, dynamic>)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error cargando últimos pagos: $e');
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

    return KpiCard(
      title: 'Últimos Pagos',
      icon: Icons.receipt_long_rounded,
      iconColor: theme.colorScheme.primary,
      trailing: _buildRefreshButton(theme),
      child: _payments.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 40,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sin pagos recientes',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                for (int i = 0; i < _payments.take(4).length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _PaymentRow(payment: _payments[i]),
                ],
              ],
            ),
    );
  }

  Widget _buildRefreshButton(ThemeData theme) {
    return IconButton(
      onPressed: () {
        final id = context.read<ProviderProvider>().selectedProviderId;
        _fetch(id);
      },
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
          title: 'Últimos Pagos',
          icon: Icons.receipt_long_rounded,
          iconColor: theme.colorScheme.primary,
          child: Column(
            children: [
              for (int i = 0; i < 5; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _skelBox(color, width: 150, height: 13),
                            const SizedBox(height: 6),
                            _skelBox(color, width: 110, height: 11),
                            const SizedBox(height: 6),
                            _skelBox(color, width: 130, height: 11),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _skelBox(color, width: 60, height: 18),
                          const SizedBox(height: 10),
                          _skelBox(color, width: 48, height: 22),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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

class _PaymentRow extends StatelessWidget {
  final _Payment payment;

  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAnulado = payment.state == 'Anulado';
    final stateColor = isAnulado
        ? theme.colorScheme.error
        : theme.extension<AppColors>()!.success;

    final dateLabel = DateFormat('yyyy-MM-dd • hh:mm a').format(payment.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stateColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: stateColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: stateColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
        children: [
          // Left: name + date + reason
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.clientName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  payment.reason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: amount + state badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${payment.amount.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isAnulado
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
                  decoration: isAnulado ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: stateColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  payment.state,
                  style: TextStyle(
                    color: stateColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
