// Pruebas de widget de los filtros de listas manuales.
//
// Verifican que el componente no se desborda en anchos estrechos
// (el riesgo detectado en la auditoría responsive) y que conserva
// todos los controles esenciales.
//
// Cómo correr: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vibeshopping/features/manual_lists/models/manual_list_entity.dart';
import 'package:vibeshopping/features/manual_lists/widgets/list/list_filter_chips.dart';

Widget _host({required double width}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: ListFilterChips(
            currentFilter: ListFilterMode.all,
            currentSort: ListSortMode.updatedAt,
            sortAscending: true,
            onFilterChanged: (_) {},
            onSortChanged: (_, __) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('no se desborda en un ancho estrecho y conserva los controles',
      (tester) async {
    await tester.pumpWidget(_host(width: 240));

    expect(tester.takeException(), isNull);

    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Vacías'), findsOneWidget);
    expect(find.text('Con productos'), findsOneWidget);
    expect(find.text('Orden:'), findsOneWidget);
    expect(find.text('Nombre'), findsOneWidget);
    expect(find.text('Actualizado'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
  });

  testWidgets('invoca los callbacks de filtro y ordenamiento',
      (tester) async {
    ListFilterMode? filter;
    ListSortMode? sort;
    bool? ascending;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListFilterChips(
          currentFilter: ListFilterMode.all,
          currentSort: ListSortMode.updatedAt,
          sortAscending: true,
          onFilterChanged: (mode) => filter = mode,
          onSortChanged: (mode, asc) {
            sort = mode;
            ascending = asc;
          },
        ),
      ),
    ));

    await tester.tap(find.text('Vacías'));
    await tester.tap(find.text('Total'));

    expect(filter, ListFilterMode.empty);
    expect(sort, ListSortMode.totalPrice);
    expect(ascending, isTrue);
  });
}
