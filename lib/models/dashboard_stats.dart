// lib/models/dashboard_stats.dart
class DashboardStats {
  final double totalRecaudado;
  final double eficienciaCobro;
  final int clientesSolventes;
  final int clientesMorosos;

  DashboardStats({
    required this.totalRecaudado,
    required this.eficienciaCobro,
    required this.clientesSolventes,
    required this.clientesMorosos,
  });
}

// Data mockeada inicial
final mockStats = DashboardStats(
  totalRecaudado: 9997.00,
  eficienciaCobro: 0.65, // 65%
  clientesSolventes: 340,
  clientesMorosos: 120,
);
