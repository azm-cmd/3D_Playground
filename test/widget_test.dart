// Smoke test for the Phase 1 renderer spike.
//
// This intentionally does NOT attempt to verify actual 3D rendering: the
// Thermion plugin talks to native platform channels that don't exist under
// `flutter test`, so viewer initialization fails fast (caught internally by
// ViewerWidget) rather than producing a real frame. That's expected here —
// real rendering, gestures, and picking can only be verified on a device or
// simulator, which this headless test environment does not have.
//
// What this test does verify: the app shell builds, mounts without
// throwing, and shows its expected chrome (AppBar title, status card).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brick_playground/catalog/brick_catalog.dart';
import 'package:brick_playground/main.dart';

void main() {
  testWidgets('app shell builds and shows expected chrome', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BrickPlaygroundApp());
    await tester.pump();

    expect(find.text('Renderer Spike (Thermion/Filament)'), findsOneWidget);
    expect(find.byType(GestureDetector), findsWidgets);
    expect(find.byType(Card), findsOneWidget);
  });

  testWidgets('the Bricks button opens the catalog dock over the viewport', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BrickPlaygroundApp());
    await tester.pump();

    // At the default (narrow) test surface size, the dock is not docked
    // beside the viewport — it opens on demand via this button.
    expect(find.text(kStarterBricks.first.name), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Bricks'));
    await tester.pumpAndSettle();

    expect(find.text('Bricks'), findsWidgets);
    expect(find.text(kStarterBricks.first.name), findsOneWidget);
  });
}
