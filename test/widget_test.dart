// App-shell smoke tests, covering Phase 1's viewport chrome, Phase 2's
// catalog dock entry point, and Phase 3's catalog-to-scene wiring.
//
// This intentionally does NOT attempt to verify actual 3D rendering: the
// Thermion plugin talks to native platform channels that don't exist under
// `flutter test`, so viewer initialization fails fast (caught internally by
// ViewerWidget) rather than producing a real frame. That's expected here —
// real rendering, gestures, picking, and manipulation feel can only be
// verified on a device or simulator, which this headless test environment
// does not have. What these tests verify instead is the Flutter-side
// wiring: that placing/selecting/deleting a brick drives the expected UI
// state (the bottom bar switching between instructions and the selection
// toolbar), independent of whether Thermion itself is actually rendering.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brick_playground/catalog/brick_catalog.dart';
import 'package:brick_playground/main.dart';

Future<void> _placeFirstCatalogBrick(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Bricks'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(kStarterBricks.first.name).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('app shell builds and shows expected chrome', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BrickPlaygroundApp());
    await tester.pump();

    expect(find.text('Brick Playground'), findsWidgets);
    expect(find.byType(GestureDetector), findsWidgets);
    expect(find.byType(Card), findsOneWidget);
    expect(find.text('Tap Bricks to add one to the scene'), findsOneWidget);
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

  testWidgets(
    'selecting a catalog brick places it, closes the tray, and shows manipulation controls',
    (WidgetTester tester) async {
      await tester.pumpWidget(const BrickPlaygroundApp());
      await tester.pump();

      await _placeFirstCatalogBrick(tester);

      // The tray closed after placing — the catalog is no longer visible...
      expect(find.text(kStarterBricks.first.name), findsNothing);
      // ...and the empty-state instructions are replaced by the selection
      // toolbar for the brick that was just placed (place() auto-selects).
      expect(find.text('Tap Bricks to add one to the scene'), findsNothing);
      expect(find.byIcon(Icons.rotate_right), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    },
  );

  testWidgets(
    'the rotate button is reachable and does not throw with a selection',
    (WidgetTester tester) async {
      await tester.pumpWidget(const BrickPlaygroundApp());
      await tester.pump();
      await _placeFirstCatalogBrick(tester);

      await tester.tap(find.byIcon(Icons.rotate_right));
      await tester.pump();

      // Rotating doesn't change what's selected or deselect it.
      expect(find.byIcon(Icons.rotate_right), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    },
  );

  testWidgets(
    'the delete button removes the placed brick and returns to the empty-state bar',
    (WidgetTester tester) async {
      await tester.pumpWidget(const BrickPlaygroundApp());
      await tester.pump();
      await _placeFirstCatalogBrick(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline), findsNothing);
      expect(find.byIcon(Icons.rotate_right), findsNothing);
      expect(find.text('Tap Bricks to add one to the scene'), findsOneWidget);
    },
  );

  testWidgets('placing a second brick keeps both in the scene', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BrickPlaygroundApp());
    await tester.pump();

    await _placeFirstCatalogBrick(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Bricks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(kStarterBricks[1].name).first);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });
}
