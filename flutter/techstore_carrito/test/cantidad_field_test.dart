import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techstore_carrito/widgets/cantidad_field.dart';

void main() {
  Future<(List<int>, List<int>)> montar(WidgetTester t, {int stock = 5}) async {
    final cambios = <int>[];
    final excesos = <int>[];
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CantidadField(
          cantidad: 1,
          stock: stock,
          onChanged: cambios.add,
          onExceso: () => excesos.add(1),
        ),
      ),
    ));
    return (cambios, excesos);
  }

  Future<void> abrirEditor(WidgetTester t) async {
    expect(find.byType(TextField), findsNothing); // starts as plain text
    await t.tap(find.text("1"));
    await t.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  }

  testWidgets('tap turns the number into a text field', (t) async {
    await montar(t);
    await abrirEditor(t);
  });

  testWidgets('rejects letters, e, + and - (digits only)', (t) async {
    final (cambios, _) = await montar(t);
    await abrirEditor(t);
    await t.enterText(find.byType(TextField), "e+-.a3");
    expect(find.text("3"), findsOneWidget);
    expect(cambios.last, 3);
  });

  testWidgets('rejects emojis and non-ASCII digits', (t) async {
    final (cambios, _) = await montar(t);
    await abrirEditor(t);
    await t.enterText(find.byType(TextField), "😀٣4🔥");
    expect(find.text("4"), findsOneWidget);
    expect(cambios.last, 4);
  });

  testWidgets('clamps to stock and reports the excess', (t) async {
    final (cambios, excesos) = await montar(t, stock: 5);
    await abrirEditor(t);
    await t.enterText(find.byType(TextField), "80");
    expect(find.text("5"), findsOneWidget);
    expect(cambios.last, 5);
    expect(excesos.length, 1);
  });

  testWidgets('empty reverts to last valid quantity and back to text', (t) async {
    await montar(t);
    await abrirEditor(t);
    await t.enterText(find.byType(TextField), "");
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text("1"), findsOneWidget);
  });
}
