import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techstore_carrito/widgets/alerta_stock.dart';

void main() {
  testWidgets('stock alert shows message and closes on button', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => mostrarAlertaStock(context, "Stock insuficiente X"),
          child: const Text("abrir"),
        ),
      ),
    ));
    await t.tap(find.text("abrir"));
    await t.pumpAndSettle();
    expect(find.text("Stock no disponible"), findsOneWidget);
    expect(find.text("Stock insuficiente X"), findsOneWidget);
    await t.tap(find.text("Entendido"));
    await t.pumpAndSettle();
    expect(find.text("Stock no disponible"), findsNothing);
  });
}
