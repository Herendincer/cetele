// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:cetele/main.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR', null);
  });

  testWidgets('app shell opens settings and exposes theme selection', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    
    expect(find.text('Genel Durum'), findsWidgets);
    await tester.tap(find.text('Ayarlar').last);
    await tester.pumpAndSettle();
    
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Sistem Teması'), findsOneWidget);
  });
}
