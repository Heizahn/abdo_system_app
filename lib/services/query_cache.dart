// lib/services/query_cache.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

/// Entrada individual en el cache.
class QueryEntry<T> {
  T data;
  DateTime fetchedAt;
  bool isFetching;

  QueryEntry({
    required this.data,
    required this.fetchedAt,
    this.isFetching = false,
  });
}

/// Estado expuesto al consumidor de una query.
class QueryState<T> {
  final T? data;
  final bool isLoading;
  final bool isRefreshing;
  final Object? error;

  const QueryState({
    this.data,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
  });
}

/// Callback que ejecuta la petición y retorna los datos.
typedef QueryFn<T> = Future<T> Function();

/// Cache central de queries inspirado en TanStack Query.
///
/// Conceptos clave:
/// - **queryKey**: String única que identifica una query (ej. 'clients:all',
///   'dashboard:solvency:provider123').
/// - **staleTime**: Tiempo en que los datos se consideran frescos. Si la data
///   tiene menos de staleTime, no se refetcha al reconstruir el widget.
/// - **refetchInterval**: Intervalo opcional para re-fetch automático en
///   background (ej. cada 10 segundos).
/// - **invalidateQueries**: Marca una o varias keys como stale, forzando
///   re-fetch en el próximo acceso. Acepta prefijos para invalidar grupos
///   (ej. 'clients' invalida 'clients:all', 'clients:123', etc.).
class QueryCache {
  QueryCache._();
  static final QueryCache instance = QueryCache._();

  final Map<String, QueryEntry<dynamic>> _cache = {};
  final Map<String, List<VoidCallback>> _listeners = {};
  final Map<String, Timer> _refetchTimers = {};

  /// Keys que fueron invalidadas con [showLoading] = true.
  /// El QueryBuilder consulta esto para decidir si mostrar el skeleton.
  final Set<String> _forceLoadingKeys = {};

  /// Registra un listener que será notificado cuando la query cambie.
  void addListener(String queryKey, VoidCallback listener) {
    _listeners.putIfAbsent(queryKey, () => []);
    _listeners[queryKey]!.add(listener);
  }

  /// Remueve un listener previamente registrado.
  void removeListener(String queryKey, VoidCallback listener) {
    _listeners[queryKey]?.remove(listener);
    if (_listeners[queryKey]?.isEmpty ?? false) {
      _listeners.remove(queryKey);
    }
  }

  void _notify(String queryKey) {
    final list = _listeners[queryKey];
    if (list != null) {
      for (final cb in List.of(list)) {
        cb();
      }
    }
  }

  /// Retorna los datos cacheados para [queryKey], o null si no hay.
  T? getData<T>(String queryKey) {
    final entry = _cache[queryKey];
    return entry?.data as T?;
  }

  /// Retorna true si la entry existe y está siendo refetchada en background.
  bool isFetching(String queryKey) {
    return _cache[queryKey]?.isFetching ?? false;
  }

  /// Retorna true si la query fue invalidada con showLoading = true.
  bool shouldForceLoading(String queryKey) =>
      _forceLoadingKeys.contains(queryKey);

  /// Limpia el flag de force loading para una query.
  void clearForceLoading(String queryKey) => _forceLoadingKeys.remove(queryKey);

  /// Retorna true si los datos son frescos (menos de [staleTime] de antigüedad).
  bool isFresh(String queryKey, Duration staleTime) {
    final entry = _cache[queryKey];
    if (entry == null) return false;
    return DateTime.now().difference(entry.fetchedAt) < staleTime;
  }

  /// Ejecuta la query y almacena el resultado en cache.
  ///
  /// Si ya hay datos cacheados, los mantiene visibles mientras refetcha
  /// en background (stale-while-revalidate).
  Future<T> fetch<T>({
    required String queryKey,
    required QueryFn<T> queryFn,
    Duration staleTime = const Duration(seconds: 30),
    bool forceRefresh = false,
  }) async {
    // Si los datos son frescos y no estamos forzando, retornar del cache
    if (!forceRefresh && isFresh(queryKey, staleTime)) {
      return _cache[queryKey]!.data as T;
    }

    // Marcar como fetching
    final existing = _cache[queryKey];
    if (existing != null) {
      existing.isFetching = true;
      _notify(queryKey);
    }

    try {
      final data = await queryFn();

      _cache[queryKey] = QueryEntry<T>(data: data, fetchedAt: DateTime.now());
      _notify(queryKey);
      return data;
    } catch (e) {
      // Si hay datos previos en cache, los mantenemos y notificamos el error
      if (existing != null) {
        existing.isFetching = false;
        _notify(queryKey);
      }
      rethrow;
    }
  }

  /// Invalida queries cuyo key empiece con [keyPrefix].
  ///
  /// Ejemplo: `invalidateQueries('clients')` invalida 'clients:all',
  /// 'clients:123', etc.
  ///
  /// Si [showLoading] es true, los QueryBuilder asociados mostrarán el
  /// skeleton/loader durante el re-fetch (útil para acciones manuales
  /// del usuario como presionar un botón de refresh).
  void invalidateQueries(String keyPrefix, {bool showLoading = false}) {
    final keysToInvalidate = _cache.keys
        .where((k) => k == keyPrefix || k.startsWith('$keyPrefix:'))
        .toList();

    for (final key in keysToInvalidate) {
      // Marcamos como stale poniendo fetchedAt en el pasado
      _cache[key]!.fetchedAt = DateTime.fromMillisecondsSinceEpoch(0);
      if (showLoading) _forceLoadingKeys.add(key);
    }

    // Notificar a los listeners para que los QueryBuilder re-fetchen
    for (final key in keysToInvalidate) {
      _notify(key);
    }
  }

  /// Actualiza los datos en cache directamente sin hacer fetch.
  /// Útil para optimistic updates después de un POST/PUT.
  void setQueryData<T>(String queryKey, T data) {
    _cache[queryKey] = QueryEntry<T>(data: data, fetchedAt: DateTime.now());
    _notify(queryKey);
  }

  /// Inicia un timer de re-fetch automático para una query.
  void startRefetchTimer<T>({
    required String queryKey,
    required QueryFn<T> queryFn,
    required Duration interval,
    Duration staleTime = const Duration(seconds: 30),
  }) {
    stopRefetchTimer(queryKey);
    _refetchTimers[queryKey] = Timer.periodic(interval, (_) {
      // Solo refetchar si hay listeners activos (alguien está usando la data)
      if (_listeners[queryKey]?.isNotEmpty ?? false) {
        fetch<T>(
          queryKey: queryKey,
          queryFn: queryFn,
          staleTime: staleTime,
          forceRefresh: true,
        ).catchError((e) {
          debugPrint('QueryCache: Error en refetch periódico [$queryKey]: $e');
          return _cache[queryKey]?.data as T;
        });
      }
    });
  }

  /// Detiene el timer de re-fetch para una query.
  void stopRefetchTimer(String queryKey) {
    _refetchTimers[queryKey]?.cancel();
    _refetchTimers.remove(queryKey);
  }

  /// Elimina una query del cache.
  void remove(String queryKey) {
    stopRefetchTimer(queryKey);
    _cache.remove(queryKey);
    _listeners.remove(queryKey);
  }

  /// Limpia todo el cache (ej. al hacer logout).
  void clear() {
    for (final timer in _refetchTimers.values) {
      timer.cancel();
    }
    _refetchTimers.clear();
    _cache.clear();
    _listeners.clear();
    _forceLoadingKeys.clear();
  }
}

/// Acceso global al singleton.
final queryCache = QueryCache.instance;
