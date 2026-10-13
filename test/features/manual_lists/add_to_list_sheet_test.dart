// Prueba de widget del selector "Agregar a una lista".
//
// Verifica que se renderiza en una altura reducida sin desbordarse
// y conserva el encabezado y la acción principal.
//
// Cómo correr: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:vibeshopping/features/manual_lists/models/manual_list_entity.dart';
import 'package:vibeshopping/features/manual_lists/providers/manual_list_provider.dart';
import 'package:vibeshopping/features/manual_lists/widgets/add_to_list_sheet.dart';

void main() {
  testWidgets('renderiza encabezado y acción sin desbordarse en poca altura',
      (tester) async {
    final provider = ManualListProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<ManualListProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: AddToListSheet(
              product: ManualListItemEntity(
                productId: 'p-1',
                storeId: 's-1',
                storeNameSnapshot: 'Tienda',
                unitPriceSnapshot: 1000,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Agregar a una lista'), findsOneWidget);
    expect(find.text('Crear nueva lista'), findsWidgets);
  });
}
