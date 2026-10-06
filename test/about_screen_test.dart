import 'package:english_fun/screens/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('about screen exposes parent-safe share and rate actions', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    await tester.pump();

    expect(find.text('Tentang English Fun'), findsOneWidget);
    expect(find.text('Bagikan aplikasi'), findsOneWidget);
    expect(find.text('Nilai di Google Play'), findsOneWidget);
    expect(find.text('Kebijakan Privasi'), findsOneWidget);
  });
}
