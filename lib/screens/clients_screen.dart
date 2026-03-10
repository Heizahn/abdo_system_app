// lib/screens/clients_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:go_router/go_router.dart';
import '../models/client_model.dart';
import '../providers/client_provider.dart';
import '../components/clients/client_card.dart';
import '../components/clients/client_card_skeleton.dart';
import '../providers/provider_provider.dart';
import '../providers/auth_provider.dart';
import '../config/roles.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  ClientStatus? _activeStatus;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  Timer? _debounce;

  // Referencia guardada para poder remover el listener en dispose
  ProviderProvider? _providerNotifier;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    // Guardamos referencia y registramos el listener una sola vez
    _providerNotifier = context.read<ProviderProvider>();
    _providerNotifier!.addListener(_onProviderChanged);

    // Carga inicial
    _fetchWithCurrentOwner();
  }

  @override
  void dispose() {
    _providerNotifier?.removeListener(_onProviderChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Llamado cuando el superadmin cambia de proveedor en el dropdown.
  void _onProviderChanged() {
    if (mounted) _fetchWithCurrentOwner();
  }

  void _fetchWithCurrentOwner() {
    final isSuperAdmin =
        context.read<AuthProvider>().user?.role == Roles.superadmin;
    final ownerId = isSuperAdmin
        ? context.read<ProviderProvider>().selectedProviderId
        : null;
    context.read<ClientProvider>().fetchClients(owner: ownerId);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      setState(() {
        _searchQuery = value.toLowerCase().trim();
      });
    });
  }

  void _onStatusChanged(ClientStatus? status) {
    setState(() {
      _activeStatus = status;
    });
  }

  List<Client> _applyFilters(List<Client> all) {
    return all.where((c) {
      final matchesStatus = _activeStatus == null || c.status == _activeStatus;
      if (!matchesStatus) return false;
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery) ||
          c.dni.toLowerCase().contains(_searchQuery) ||
          c.phone.contains(_searchQuery) ||
          c.sectorName.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Widget _buildBody(
    BuildContext context,
    ClientProvider provider,
    List<Client> filtered,
  ) {
    if (provider.state == ClientsState.loading) {
      return const ClientCardSkeletonList();
    }
    if (provider.state == ClientsState.error) {
      return _ErrorState(
        message: provider.error,
        onRetry: _fetchWithCurrentOwner,
      );
    }
    if (filtered.isEmpty) {
      return _EmptyState(hasSearch: _searchQuery.isNotEmpty);
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final client = filtered[index];
        return Padding(
          key: ValueKey(client.id),
          padding: const EdgeInsets.only(bottom: 8),
          child: ClientCard(
            client: client,
            onTap: () => context.push('/client/${client.id}'),
          ),
        );
      },
    );
  }

  Map<ClientStatus?, int> _countsByStatus(List<Client> base) {
    final searched = _searchQuery.isEmpty
        ? base
        : base.where((c) {
            return c.name.toLowerCase().contains(_searchQuery) ||
                c.dni.toLowerCase().contains(_searchQuery) ||
                c.phone.contains(_searchQuery) ||
                c.sectorName.toLowerCase().contains(_searchQuery);
          }).toList();

    return {
      null: searched.length,
      ClientStatus.solvente: searched
          .where((c) => c.status == ClientStatus.solvente)
          .length,
      ClientStatus.moroso: searched
          .where((c) => c.status == ClientStatus.moroso)
          .length,
      ClientStatus.suspendido: searched
          .where((c) => c.status == ClientStatus.suspendido)
          .length,
      ClientStatus.retirado: searched
          .where((c) => c.status == ClientStatus.retirado)
          .length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clientProvider = context.watch<ClientProvider>();
    final filtered = _applyFilters(clientProvider.clients);

    return Column(
      children: [
        // ─── BARRA DE BÚSQUEDA ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, cédula, teléfono...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
            ),
          ),
        ),

        // ─── CHIPS DE FILTRO ─────────────────────────────────────────────
        _FilterBar(
          activeStatus: _activeStatus,
          counts: _countsByStatus(clientProvider.clients),
          onChanged: _onStatusChanged,
        ),

        // ─── CONTADOR DE RESULTADOS ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          child: Row(
            children: [
              Text(
                '${filtered.length} cliente${filtered.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                iconSize: 20,
                tooltip: 'Actualizar',
                onPressed: clientProvider.state == ClientsState.loading
                    ? null
                    : _fetchWithCurrentOwner,
              ),
            ],
          ),
        ),

        // ─── CONTENIDO ───────────────────────────────────────────────────
        Expanded(child: _buildBody(context, clientProvider, filtered)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// FILTER BAR
// ---------------------------------------------------------------------------
class _FilterBar extends StatelessWidget {
  final ClientStatus? activeStatus;
  final Map<ClientStatus?, int> counts;
  final ValueChanged<ClientStatus?> onChanged;

  const _FilterBar({
    required this.activeStatus,
    required this.counts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _FilterChip(
            label: 'Todos',
            count: counts[null] ?? 0,
            isSelected: activeStatus == null,
            color: Theme.of(context).colorScheme.primary,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Solventes',
            count: counts[ClientStatus.solvente] ?? 0,
            isSelected: activeStatus == ClientStatus.solvente,
            color: Theme.of(context).colorScheme.primary,
            onTap: () => onChanged(ClientStatus.solvente),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Morosos',
            count: counts[ClientStatus.moroso] ?? 0,
            isSelected: activeStatus == ClientStatus.moroso,
            color: Theme.of(context).colorScheme.outline,
            onTap: () => onChanged(ClientStatus.moroso),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Suspendidos',
            count: counts[ClientStatus.suspendido] ?? 0,
            isSelected: activeStatus == ClientStatus.suspendido,
            color: Theme.of(context).colorScheme.error,
            onTap: () => onChanged(ClientStatus.suspendido),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Retirados',
            count: counts[ClientStatus.retirado] ?? 0,
            isSelected: activeStatus == ClientStatus.retirado,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            onTap: () => onChanged(ClientStatus.retirado),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected ? color : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : theme.colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EMPTY STATE
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final bool hasSearch;

  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearch ? Icons.search_off_rounded : Icons.group_off_rounded,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'Sin resultados' : 'Sin clientes',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch
                ? 'Intenta con otro término de búsqueda.'
                : 'No hay clientes en esta categoría.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ERROR STATE
// ---------------------------------------------------------------------------
class _ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _ErrorState({this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
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
              'Error al cargar clientes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
