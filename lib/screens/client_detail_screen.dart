// lib/screens/client_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/client_detail_model.dart';
import '../services/api_client.dart';
import '../components/query_builder.dart';
import '../components/client_detail/client_detail_header.dart';
import '../components/client_detail/cards/personal_info_card.dart';
import '../components/client_detail/cards/plan_info_card.dart';
import '../components/client_detail/cards/status_info_card.dart';
import '../components/client_detail/cards/devices_info_card.dart';

class ClientDetailScreen extends StatelessWidget {
  final String clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return QueryBuilder<ClientDetail>(
      queryKey: 'client:$clientId',
      queryFn: () async {
        final response = await apiClient.get('/auth-user/clients/$clientId');
        return ClientDetail.fromJson(response.data as Map<String, dynamic>);
      },
      staleTime: const Duration(minutes: 2),
      loading: _LoadingScreen(clientId: clientId),
      onError: (error, retry) =>
          _ErrorScreen(onRetry: retry, onBack: () => context.pop()),
      builder: (context, client, isRefreshing) =>
          _ClientDetailView(client: client),
    );
  }
}

// ─── Vista principal ──────────────────────────────────────────────────────────

class _ClientDetailView extends StatelessWidget {
  final ClientDetail client;

  const _ClientDetailView({required this.client});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final devices = DevicesInfoData(
      ip: client.ip,
      ipPppoe: client.ipPppoe,
      sn: client.sn,
      mac: client.mac,
      clientType: client.clientType,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Ficha del Cliente',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: ClientDetailHeader(client: client)),
          SliverToBoxAdapter(
            child: Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                PersonalInfoCard(
                  data: PersonalInfoData(
                    dni: client.dni,
                    phone: client.phone,
                    email: client.email,
                    sectorName: client.sectorName,
                    address: client.address,
                    commentary: client.commentary,
                  ),
                ),
                const SizedBox(height: 20),
                PlanInfoCard(
                  data: PlanInfoData(
                    planName: client.planName,
                    planPrice: client.planPrice,
                    planMbps: client.planMbps,
                    paymentDay: client.paymentDay,
                  ),
                ),
                if (devices.hasAnyData) ...[
                  const SizedBox(height: 20),
                  DevicesInfoCard(data: devices),
                ],
                const SizedBox(height: 20),
                StatusInfoCard(
                  data: StatusInfoData(
                    status: client.status,
                    balance: client.balance,
                    creator: client.creator,
                    editor: client.editor,
                    suspender: client.suspender,
                    createdAt: client.createdAt,
                    suspendedAt: client.suspendedAt,
                    installedAt: client.installedAt,
                    providerTag: client.providerTag,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading ──────────────────────────────────────────────────────────────────

class _LoadingScreen extends StatelessWidget {
  final String clientId;

  const _LoadingScreen({required this.clientId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Ficha del Cliente',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────────────────

class _ErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _ErrorScreen({required this.onRetry, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: onBack,
        ),
        title: const Text(
          'Ficha del Cliente',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: theme.colorScheme.error.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar el cliente',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Volver'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
