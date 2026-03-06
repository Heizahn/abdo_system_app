// lib/providers/client_provider.dart
import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../services/api_client.dart';

enum ClientsState { idle, loading, loaded, error }

class ClientProvider extends ChangeNotifier {
  List<Client> _clients = [];
  ClientsState _state = ClientsState.idle;
  String? _error;

  List<Client> get clients => _clients;
  ClientsState get state => _state;
  String? get error => _error;

  Future<void> fetchClients({String? owner}) async {
    _state = ClientsState.loading;
    _error = null;
    notifyListeners();

    try {
      final queryParams = (owner != null && owner != 'all')
          ? {'owner': owner}
          : <String, dynamic>{};
      final response = await apiClient.get(
        '/auth-user/clients/all',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = response.data as List<dynamic>;
      _clients = data
          .map((e) => Client.fromJson(e as Map<String, dynamic>))
          .toList();
      _state = ClientsState.loaded;
    } catch (e, st) {
      debugPrint('❌ ClientProvider.fetchClients error: $e\n$st');
      _error = e.toString();
      _state = ClientsState.error;
    } finally {
      notifyListeners();
    }
  }
}
