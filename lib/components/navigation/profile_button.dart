import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Observamos los estados
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    final user = authProvider.user;
    final initial = user?.name.isNotEmpty == true
        ? user!.name[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 45), // Desplaza el menú debajo del botón
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: theme.colorScheme.surface,
        // El gatillo del menú es el Avatar
        icon: CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF3B82F6),
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onSelected: (value) async {
          if (value == 'logout') {
            await authProvider.logout();
            if (context.mounted) context.go('/login');
          } else if (value == 'theme_light') {
            themeProvider.setThemeMode(ThemeMode.light);
          } else if (value == 'theme_dark') {
            themeProvider.setThemeMode(ThemeMode.dark);
          } else if (value == 'theme_system') {
            themeProvider.setThemeMode(ThemeMode.system);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          // HEADER: Nombre del Usuario (No clickeable)
          PopupMenuItem<String>(
            value: 'header',
            enabled: false,
            child: Row(
              children: [
                Icon(
                  Icons.account_circle,
                  size: 24,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Text(
                  user?.name ?? 'Usuario',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const PopupMenuDivider(),

          // OPCIONES DE TEMA
          PopupMenuItem<String>(
            value: 'theme_system',
            child: _buildThemeItem(
              icon: Icons.brightness_auto_rounded,
              label: 'Tema del Sistema',
              isSelected: themeProvider.themeMode == ThemeMode.system,
              theme: theme,
            ),
          ),
          PopupMenuItem<String>(
            value: 'theme_light',
            child: _buildThemeItem(
              icon: Icons.light_mode_rounded,
              label: 'Modo Claro',
              isSelected: themeProvider.themeMode == ThemeMode.light,
              theme: theme,
            ),
          ),
          PopupMenuItem<String>(
            value: 'theme_dark',
            child: _buildThemeItem(
              icon: Icons.dark_mode_rounded,
              label: 'Modo Oscuro',
              isSelected: themeProvider.themeMode == ThemeMode.dark,
              theme: theme,
            ),
          ),

          const PopupMenuDivider(),

          // CERRAR SESIÓN
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 12),
                Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pequeño widget ayudante para pintar el ítem del tema seleccionado del color primario
  Widget _buildThemeItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required ThemeData theme,
  }) {
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
