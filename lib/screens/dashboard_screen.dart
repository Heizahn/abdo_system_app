import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/roles.dart';
import '../layouts/main_layout.dart';
import '../components/dashboard/client_status_card.dart';
import '../components/dashboard/latest_payments_card.dart';
import '../components/dashboard/monthly_closing_card.dart';
import '../components/navigation/provider_dropdown.dart';
import '../providers/auth_provider.dart';
import '../providers/provider_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentProviderId = context.watch<ProviderProvider>().selectedProviderId;
    final isSuperAdmin =
        context.watch<AuthProvider>().user?.role == Roles.superadmin;

    return MainLayout(
      title: 'Panel',
      actions: [
        if (isSuperAdmin)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: ProviderDropdown(showAllOption: true),
            ),
          ),
      ],
      child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER: RESUMEN OPERATIVO ---
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.grid_view_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resumen Operativo',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              currentProviderId == 'all'
                                  ? 'Visualización de todos los proveedores.'
                                  : 'Datos específicos del proveedor seleccionado.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- KPI: CIERRE MENSUAL ---
                  const MonthlyClosingCard(),

                  const SizedBox(height: 16),

                  // --- KPI: ESTADO DE CLIENTES ---
                  const ClientStatusCard(),

                  const SizedBox(height: 32),

                  // --- ACTIVIDAD DE PAGOS ---
                  const LatestPaymentsCard(),
                ],
              ),
            ),
    );
  }
}
