// Contenedor de navegación principal adaptativo.
//
// - Móvil: barra inferior (NavigationBar).
// - Tablet: riel compacto con etiquetas (NavigationRail).
// - Escritorio: riel expandido con etiquetas.
//
// El contenido de cada sección se conserva mediante IndexedStack, de modo que
// cambiar de destino mantiene el estado actual de cada pantalla.

import 'package:flutter/material.dart';
import '../../../core/responsive.dart';

class VibeNavigationScaffold extends StatelessWidget {
  const VibeNavigationScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.children,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget> children;

  static const List<_VibeNavItem> _items = [
    _VibeNavItem(Icons.explore_outlined, Icons.explore, 'Explorar'),
    _VibeNavItem(Icons.list_alt_rounded, Icons.list_alt_rounded, 'Mis Listas'),
    _VibeNavItem(Icons.location_on_outlined, Icons.location_on, 'Ubicación'),
    _VibeNavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = VibeResponsive.fromWidth(constraints.maxWidth);
        final body = IndexedStack(index: selectedIndex, children: children);

        if (size == VibeScreenSize.mobile) {
          return Scaffold(
            body: body,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final item in _items)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.label,
                  ),
              ],
            ),
          );
        }

        final extended = size == VibeScreenSize.desktop;
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                right: false,
                child: NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  extended: extended,
                  labelType: extended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: [
                    for (final item in _items)
                      NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: Text(item.label),
                      ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}

class _VibeNavItem {
  const _VibeNavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
