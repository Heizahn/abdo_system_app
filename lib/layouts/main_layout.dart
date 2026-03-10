import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../config/roles.dart';
import '../components/navigation/profile_button.dart';
import '../components/navigation/provider_dropdown.dart';
import '../screens/dashboard_screen.dart';
import '../screens/clients_screen.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;

  const MainLayout({super.key, required this.initialIndex});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  static const _tabs = [
    _TabItem(icon: Icons.dashboard_rounded, label: 'Panel', path: '/home'),
    _TabItem(icon: Icons.group_rounded, label: 'Clientes', path: '/clients'),
  ];

  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void didUpdateWidget(MainLayout old) {
    super.didUpdateWidget(old);
    // Solo si el índice cambia por navegación externa (ej: redirect por rol)
    if (old.initialIndex != widget.initialIndex) {
      _pageController.jumpToPage(widget.initialIndex);
      setState(() => _currentIndex = widget.initialIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    // Solo actualiza el índice visualmente — sin llamar context.go()
    // para que el NavigationBar no se mueva con la transición de GoRouter
    setState(() => _currentIndex = index);
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSuperAdmin =
        context.watch<AuthProvider>().user?.role == Roles.superadmin;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,

        // ── AppBar ──────────────────────────────────────────────────────
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            _tabs[_currentIndex].label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          actions: [
            if (isSuperAdmin)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Center(
                  child: const ProviderDropdown(showAllOption: true),
                ),
              ),
            const ProfileButton(),
          ],
        ),

        // ── PageView ────────────────────────────────────────────────────
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: const [DashboardScreen(), ClientsScreen()],
        ),

        // ── NavigationBar ───────────────────────────────────────────────
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabTapped,
          destinations: _tabs.map((tab) {
            return NavigationDestination(
              icon: Icon(tab.icon),
              label: tab.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final String path;

  const _TabItem({required this.icon, required this.label, required this.path});
}
