// lib/providers/client_provider.dart
import 'package:flutter/material.dart';

import '../models/client_model.dart';
import '../services/api_client.dart';
import '../services/query_cache.dart';

enum ClientsState { idle, loading, loaded, error }

class ClientProvider extends ChangeNotifier {
  List<Client> _clients = [];
  ClientsState _state = ClientsState.idle;
  String? _error;
  String _lastQueryKey = '';

  List<Client> get clients => _clients;
  ClientsState get state => _state;
  String? get error => _error;

  /// Genera la query key basada en el owner.
  static String queryKey({String? owner}) {
    if (owner == null || owner == 'all') return 'clients:all';
    return 'clients:$owner';
  }

  Future<void> fetchClients({String? owner}) async {
    final key = queryKey(owner: owner);

    // Verificar si hay datos en cache frescos
    final cached = queryCache.getData<List<Client>>(key);
    if (cached != null &&
        queryCache.isFresh(key, const Duration(seconds: 30))) {
      // Datos frescos en cache: actualizar sin mostrar loader
      _clients = cached;
      _state = ClientsState.loaded;
      _error = null;
      _lastQueryKey = key;
      notifyListeners();
      return;
    }

    // Si hay datos cacheados (stale), mostrarlos mientras refetchamos
    if (cached != null) {
      _clients = cached;
      _state = ClientsState.loaded;
      notifyListeners();
    } else {
      _state = ClientsState.loading;
      _error = null;
      notifyListeners();
    }

    _lastQueryKey = key;

    try {
      final data = await queryCache.fetch<List<Client>>(
        queryKey: key,
        queryFn: () => _fetchFromApi(owner),
        forceRefresh: true,
      );
      _clients = data;
      _state = ClientsState.loaded;
      _error = null;
    } catch (e, st) {
      debugPrint('ClientProvider.fetchClients error: $e\n$st');
      // Si tenemos datos previos, los mantenemos
      if (_clients.isEmpty) {
        _error = e.toString();
        _state = ClientsState.error;
      }
    } finally {
      notifyListeners();
    }
  }

  /// Petición directa a la API.
  static Future<List<Client>> _fetchFromApi(String? owner) async {
    final queryParams = (owner != null && owner != 'all')
        ? {'owner': owner}
        : <String, dynamic>{};
    final response = await apiClient.get(
      '/auth-user/clients/all',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final data = response.data as List<dynamic>;
    return data.map((e) => Client.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Invalida el cache de clientes, forzando re-fetch en el próximo acceso.
  void invalidate() {
    queryCache.invalidateQueries('clients');
    // Si hay una key activa, refetchar inmediatamente
    if (_lastQueryKey.isNotEmpty) {
      fetchClients(
        owner: _lastQueryKey == 'clients:all'
            ? null
            : _lastQueryKey.replaceFirst('clients:', ''),
      );
    }
  }
}
