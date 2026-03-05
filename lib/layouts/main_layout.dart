import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para poder salir de la app (SystemNavigator)
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart'; // Asegúrate de tener esta ruta correcta
import '../components/navigation/profile_button.dart';

// 1. AHORA ES UN STATEFUL WIDGET
class MainLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;

  const MainLayout({
    super.key,
    required this.child,
    required this.title,
    this.actions,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // LLAVE MAESTRA: Nos permite preguntarle al Scaffold su estado desde cualquier lado
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Recuperamos al usuario real (¡No perdamos esta funcionalidad!)
    final user = context.watch<AuthProvider>().user;

    // 2. POPSCOPE INTERCEPTA EL BOTÓN DE "ATRÁS" DE ANDROID
    return PopScope(
      canPop:
          false, // Le decimos a Flutter: "Espera, yo decido qué hace el botón de atrás"
      onPopInvoked: (didPop) {
        if (didPop) return;

        // ¿Está el menú lateral abierto?
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          // Sí -> Ciérralo, pero NO salgas de la ruta
          _scaffoldKey.currentState?.closeDrawer();
        } else {
          // No -> Comportamiento normal
          if (GoRouter.of(context).canPop()) {
            // Si hay historial de navegación, ve a la pantalla anterior
            GoRouter.of(context).pop();
          } else {
            // Si es la pantalla principal, cierra la aplicación nativamente
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey, // Asignamos la llave al Scaffold
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.title, // Ahora usamos widget.title por ser StatefulWidget
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          actions: [...?widget.actions, const ProfileButton()],
        ),
        drawer: Drawer(
          backgroundColor: theme.colorScheme.surface,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SvgPicture.asset(
                    'lib/assets/logo.svg',
                    height: 40,
                    colorFilter: theme.brightness == Brightness.dark
                        ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                        : null,
                  ),
                ),

                // MUESTRA EL NOMBRE DEL USUARIO DEBAJO DEL LOGO
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Hola, ${user.name}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    children: const [
                      _DrawerItem(
                        icon: Icons.dashboard_rounded,
                        title: 'Panel',
                        path: '/home',
                      ),
                      _DrawerItem(
                        icon: Icons.group_rounded,
                        title: 'Clientes',
                        path: '/clients',
                      ),
                      _DrawerItem(
                        icon: Icons.payments_rounded,
                        title: 'Pagos',
                        path: '/payments',
                      ),
                      _DrawerItem(
                        icon: Icons.speed_rounded,
                        title: 'Planes',
                        path: '/services',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    leading: Icon(
                      Icons.logout_rounded,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      await Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        body: widget.child, // Ahora usamos widget.child
      ),
    );
  }
}

// Widget privado para los items del Drawer (Queda exactamente igual)
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String path;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = GoRouterState.of(
      context,
    ).matchedLocation.startsWith(path);

    return ListTile(
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(
        icon,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Cierra el drawer
        if (!isSelected) context.go(path); // Navega si es una ruta nueva
      },
    );
  }
}
