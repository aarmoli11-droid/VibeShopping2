// Shell principal: bottom navigation entre Explorar, Mis Listas,
// Ubicación y Perfil.

import 'package:flutter/material.dart';
import '../../manual_lists/screens/manual_lists_view.dart';
import '../../auth/screens/profile_view.dart';
import '../../location_demo/location_demo_screen.dart';
import 'market_explorer_view.dart';

class ExplorerShell extends StatefulWidget {
  const ExplorerShell({super.key});

  @override
  State<ExplorerShell> createState() => _ExplorerShellState();
}

class _ExplorerShellState extends State<ExplorerShell> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          const MarketExplorerView(),
          const ManualListsView(),
          // IndexedStack monta todos los tabs; isActive indica cuándo el tab
          // Ubicación está visible para recién entonces pedir la ubicación.
          LocationDemoScreen(isActive: _navIndex == 2),
          const ProfileView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_rounded),
            selectedIcon: Icon(Icons.list_alt_rounded),
            label: 'Mis Listas',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Ubicación',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
