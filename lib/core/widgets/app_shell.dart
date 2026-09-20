import 'package:flutter/material.dart';

import '../../features/cash_bank/presentation/cash_bank_screen.dart';
import '../../features/contacts/presentation/contacts_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/invoices/presentation/invoices_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}

final List<_ShellDestination> _destinations = [
  const _ShellDestination(
    label: 'Genel Durum',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    screen: DashboardScreen(),
  ),
  const _ShellDestination(
    label: 'Faturalar',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
    screen: InvoicesScreen(),
  ),
  const _ShellDestination(
    label: 'Cariler',
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
    screen: ContactsScreen(),
  ),
  const _ShellDestination(
    label: 'Kasa/Banka',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet_rounded,
    screen: CashBankScreen(),
  ),
  const _ShellDestination(
    label: 'Ayarlar',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    screen: SettingsScreen(),
  ),
];

/// Dar ekranlarda alt navigasyon çubuğu, geniş ekranlarda yan navigasyon
/// rayı kullanan responsive uygulama iskeleti.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.sizeOf(context).width >= 900;
    final Widget currentScreen = _destinations[_selectedIndex].screen;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final destination in _destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: currentScreen),
          ],
        ),
      );
    }

    return Scaffold(
      body: currentScreen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}
