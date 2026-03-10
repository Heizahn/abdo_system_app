// lib/components/query_builder.dart
import 'package:flutter/material.dart';

import '../services/query_cache.dart';

/// Widget que consume el [QueryCache], análogo a useQuery de TanStack Query.
///
/// Comportamiento:
/// 1. Si hay datos en cache, los muestra inmediatamente (sin loader).
/// 2. Si los datos están stale, refetcha en background y actualiza la UI
///    cuando llegan los datos nuevos.
/// 3. Si no hay datos en cache, muestra el [loading] widget mientras fetcha.
/// 4. Si se configura [refetchInterval], crea un timer periódico que
///    refresca la data automáticamente.
///
/// Uso básico:
/// ```dart
/// QueryBuilder<List<Client>>(
///   queryKey: 'clients:all',
///   queryFn: () async {
///     final res = await apiClient.get('/auth-user/clients/all');
///     return (res.data as List).map((e) => Client.fromJson(e)).toList();
///   },
///   builder: (context, data) => ListView(...),
///   loading: const CircularProgressIndicator(),
/// )
/// ```
class QueryBuilder<T> extends StatefulWidget {
  /// Key única que identifica esta query en el cache.
  final String queryKey;

  /// Función que ejecuta la petición HTTP y retorna los datos.
  final QueryFn<T> queryFn;

  /// Builder que recibe los datos cacheados.
  /// [isRefreshing] es true cuando se está actualizando en background.
  final Widget Function(BuildContext context, T data, bool isRefreshing)
  builder;

  /// Widget a mostrar mientras se cargan los datos por primera vez
  /// (cuando no hay nada en cache).
  final Widget loading;

  /// Widget opcional para mostrar errores cuando no hay datos previos
  /// en cache. Recibe el error y un callback para reintentar.
  final Widget Function(Object error, VoidCallback retry)? onError;

  /// Tiempo que los datos se consideran frescos. Por defecto 30 segundos.
  final Duration staleTime;

  /// Intervalo opcional para re-fetch automático en background.
  final Duration? refetchInterval;

  /// Si es true, muestra el loader incluso si hay datos en cache
  /// (útil para la primera carga de pantallas críticas). Por defecto false.
  final bool showLoadingOnRefresh;

  const QueryBuilder({
    super.key,
    required this.queryKey,
    required this.queryFn,
    required this.builder,
    required this.loading,
    this.onError,
    this.staleTime = const Duration(seconds: 30),
    this.refetchInterval,
    this.showLoadingOnRefresh = false,
  });

  @override
  State<QueryBuilder<T>> createState() => _QueryBuilderState<T>();
}

class _QueryBuilderState<T> extends State<QueryBuilder<T>> {
  Object? _error;
  bool _isFirstLoad = true;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    queryCache.addListener(widget.queryKey, _onCacheUpdate);
    _fetchIfNeeded();
    _setupRefetchTimer();
  }

  @override
  void didUpdateWidget(covariant QueryBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.queryKey != widget.queryKey) {
      // La key cambió (ej. cambio de provider), re-suscribirse
      queryCache.removeListener(oldWidget.queryKey, _onCacheUpdate);
      queryCache.stopRefetchTimer(oldWidget.queryKey);
      queryCache.addListener(widget.queryKey, _onCacheUpdate);
      _error = null;
      _isFirstLoad = queryCache.getData<T>(widget.queryKey) == null;
      _fetchIfNeeded();
      _setupRefetchTimer();
    }
  }

  @override
  void dispose() {
    queryCache.removeListener(widget.queryKey, _onCacheUpdate);
    queryCache.stopRefetchTimer(widget.queryKey);
    super.dispose();
  }

  void _onCacheUpdate() {
    if (mounted) setState(() {});
  }

  void _setupRefetchTimer() {
    if (widget.refetchInterval != null) {
      queryCache.startRefetchTimer<T>(
        queryKey: widget.queryKey,
        queryFn: widget.queryFn,
        interval: widget.refetchInterval!,
        staleTime: widget.staleTime,
      );
    }
  }

  Future<void> _fetchIfNeeded() async {
    if (queryCache.isFresh(widget.queryKey, widget.staleTime)) {
      if (mounted) setState(() => _isFirstLoad = false);
      return;
    }
    await _doFetch();
  }

  Future<void> _doFetch() async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      await queryCache.fetch<T>(
        queryKey: widget.queryKey,
        queryFn: widget.queryFn,
        staleTime: widget.staleTime,
        forceRefresh: true,
      );
      if (mounted) {
        setState(() {
          _error = null;
          _isFirstLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isFirstLoad = queryCache.getData<T>(widget.queryKey) == null;
        });
      }
    } finally {
      _isFetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cachedData = queryCache.getData<T>(widget.queryKey);
    final isRefreshing = queryCache.isFetching(widget.queryKey) || _isFetching;

    // Primera carga sin datos: mostrar loader
    if (cachedData == null && _isFirstLoad && _error == null) {
      return widget.loading;
    }

    // Error sin datos previos en cache
    if (cachedData == null && _error != null) {
      if (widget.onError != null) {
        return widget.onError!(_error!, _doFetch);
      }
      return widget.loading;
    }

    // Hay datos (frescos o stale): mostrarlos
    if (cachedData != null) {
      if (widget.showLoadingOnRefresh && isRefreshing && _isFirstLoad) {
        return widget.loading;
      }
      return widget.builder(context, cachedData, isRefreshing);
    }

    return widget.loading;
  }
}
