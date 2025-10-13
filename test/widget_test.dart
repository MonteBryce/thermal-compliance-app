import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ProviderScope renders MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp()));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
