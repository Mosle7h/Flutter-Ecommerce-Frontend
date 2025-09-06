import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'widget_product_catalog.dart'; // import above widget file

void main() {
  testWidgets(
    'Catalog screen shows product list and add-to-cart button works',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductCatalog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
      await tester.tap(find.byIcon(Icons.add_shopping_cart).first);
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Added'), findsOneWidget);
    },
  );
}
