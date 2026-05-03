import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/app_theme.dart';
import '../blocs/category_cubit.dart';
import 'dashboard_page.dart';
import 'reports_page.dart';
import 'loans_page.dart';
import 'settings_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [
    DashboardPage(),
    ReportsPage(),
    LoansPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 3) {
            context.read<CategoryCubit>().loadCategories();
          }
        },
        backgroundColor: c.surface,
        indicatorColor: c.primaryMuted,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: c.iconMuted),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: c.primary),
            label: 'Transacciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: c.iconMuted),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: c.primary),
            label: 'Reportes',
          ),
          NavigationDestination(
            icon: Icon(Icons.handshake_outlined, color: c.iconMuted),
            selectedIcon: Icon(Icons.handshake_rounded, color: c.primary),
            label: 'Préstamos',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: c.iconMuted),
            selectedIcon: Icon(Icons.settings_rounded, color: c.primary),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}
