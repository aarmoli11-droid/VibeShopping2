// Shell principal: navegación adaptativa entre Explorar, Mis Listas,
// Ubicación y Perfil (barra inferior en móvil, riel en tablet/escritorio).

import 'package:flutter/material.dart';
import '../../manual_lists/screens/manual_lists_view.dart';
import '../../auth/screens/profile_view.dart';
import '../../location_demo/location_demo_screen.dart';
import '../widgets/vibe_navigation_scaffold.dart';
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
    return VibeNavigationScaffold(
      selectedIndex: _navIndex,
      onDestinationSelected: (i) => setState(() => _navIndex = i),
      children: [
        const MarketExplorerView(),
        const ManualListsView(),
        // IndexedStack monta todos los tabs; isActive indica cuándo el tab
        // Ubicación está visible para recién entonces pedir la ubicación.
        LocationDemoScreen(isActive: _navIndex == 2),
        const ProfileView(),
      ],
    );
  }
}
