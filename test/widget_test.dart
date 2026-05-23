import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:eventos_app/app/app.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  testWidgets('EventosApp carga MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const EventosApp());
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
