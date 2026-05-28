import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventos_app/address_search_field.dart';

void main() {
  testWidgets(
    'Debounce test: debe llamar a onSearch una sola vez después del retraso',
    (WidgetTester tester) async {
      String? lastSearchQuery;
      int callCount = 0;

      // 1. Construimos el widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressSearchField(
              debounceTime: const Duration(milliseconds: 500),
              onSearch: (query) {
                lastSearchQuery = query;
                callCount++;
              },
            ),
          ),
        ),
      );

      // 2. Simulamos que el usuario escribe varias veces rápido
      await tester.enterText(find.byType(TextField), 'Calle');
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // Menos que el tiempo de debounce

      await tester.enterText(find.byType(TextField), 'Calle Falsa');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(find.byType(TextField), 'Calle Falsa 123');

      // 3. Verificamos que, aunque escribimos 3 veces, la búsqueda aún NO se ha ejecutado
      expect(callCount, 0);

      // 4. Avanzamos el tiempo simulado para que el debounce expire (500ms)
      await tester.pump(const Duration(milliseconds: 500));

      // 5. Verificamos que se llamó exactamente una vez y con el último valor ingresado
      expect(callCount, 1);
      expect(lastSearchQuery, 'Calle Falsa 123');
    },
  );
}
