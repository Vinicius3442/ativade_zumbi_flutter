import 'package:flutter_test/flutter_test.dart';
import 'package:protocolo_z/models/faction_model.dart';
import 'package:protocolo_z/models/item_model.dart';
import 'package:protocolo_z/widgets/survival_2d_art.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Renderiza logotipo 2D do Protocolo Z e valida seed de facções', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: ProtocoloZLogo2D(size: 120)),
        ),
      ),
    );

    expect(find.byType(ProtocoloZLogo2D), findsOneWidget);
    expect(FactionModel.defaultFactions.length, greaterThanOrEqualTo(3));
    expect(ItemModel.defaultCatalog.where((i) => i.isStarterItem).length, 4);
  });
}
