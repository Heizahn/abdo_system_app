import 'package:flutter/material.dart';

class ProviderProvider extends ChangeNotifier {
  String _selectedProviderId = 'all';

  String get selectedProviderId => _selectedProviderId;

  void setProvider(String id) {
    if (_selectedProviderId != id) {
      _selectedProviderId = id;
      print('🌐 Estado Global: Proveedor cambiado a $id');
      notifyListeners(); // Esto notificará a todas las pantallas
    }
  }
}
