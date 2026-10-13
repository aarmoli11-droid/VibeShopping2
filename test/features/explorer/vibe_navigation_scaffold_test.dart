// Pruebas de widget de la navegación principal adaptativa.
//
// Verifican que la barra cambia a riel (tablet/escritorio), que las etiquetas
// permanecen visibles y que la selección de destinos funciona en cada ancho.
//
// Cómo correr: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vibeshopping/features/explorer/widgets/vibe_navigation_scaffold.dart';

Widget _host({int selected = 0, ValueChanged<int>? onSelected}) {
  return MaterialApp(
    home: VibeNavigationScaffold(
      selectedIndex: selected,
      onDestinationSelected: onSelected ?? (_) {},
      children: const [
        Center(child: Text('cuerpo-explorar')),
        Center(child: Text('cuerpo-listas')),
        Center(child: Text('cuerpo-ubicacion')),
        Center(child: Text('cuerpo-perfil')),
      ],
    ),
  );
}

Future<void> _setWidth(WidgetTester tester, double width) async {
  await tester.binding.setSurfaceSize(Size(width, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets('en móvil usa barra inferior con las cuatro etiquetas',
      (tester) async {
    await _setWidth(tester, 390);
    await tester.pumpWidget(_host());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    expect(find.text('Explorar'), findsOneWidget);
    expect(find.text('Mis Listas'), findsOneWidget);
    expect(find.text('Ubicación'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en tablet usa riel compacto con etiquetas', (tester) async {
    await _setWidth(tester, 800);
    await tester.pumpWidget(_host());

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(rail.labelType, NavigationRailLabelType.all);
    expect(find.text('Ubicación'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en escritorio usa riel expandido', (tester) async {
    await _setWidth(tester, 1440);
    await tester.pumpWidget(_host());

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(find.text('Mis Listas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra el cuerpo correspondiente al índice seleccionado',
      (tester) async {
    await _setWidth(tester, 390);
    await tester.pumpWidget(_host(selected: 2));

    expect(find.text('cuerpo-ubicacion'), findsOneWidget);
  });

  testWidgets('invoca onDestinationSelected con el índice tocado',
      (tester) async {
    int? tapped;
    await _setWidth(tester, 390);
    await tester.pumpWidget(_host(onSelected: (i) => tapped = i));

    await tester.tap(find.text('Mis Listas'));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('invoca onDestinationSelected desde el riel en escritorio',
      (tester) async {
    int? tapped;
    await _setWidth(tester, 1440);
    await tester.pumpWidget(_host(onSelected: (i) => tapped = i));

    await tester.tap(find.text('Ubicación'));
    await tester.pump();

    expect(tapped, 2);
  });
}
