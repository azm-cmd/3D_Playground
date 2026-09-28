// Widget tests for the brick browse/search dock. These pump BrickDock in
// isolation (not the full app), so they don't depend on the Thermion
// viewport or its plugin channels at all.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brick_playground/catalog/brick_catalog.dart';
import 'package:brick_playground/catalog/brick_catalog_card.dart';
import 'package:brick_playground/catalog/brick_definition.dart';
import 'package:brick_playground/catalog/brick_dock.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(height: 800, width: 400, child: child)),
  );
}

void main() {
  testWidgets('shows every starter brick by default', (tester) async {
    await tester.pumpWidget(_wrap(const BrickDock()));
    await tester.pumpAndSettle();

    expect(find.byType(BrickCatalogCard), findsNWidgets(kStarterBricks.length));
    for (final brick in kStarterBricks) {
      expect(find.text(brick.name), findsOneWidget);
    }
    expect(
      find.text('${kStarterBricks.length} of ${kStarterBricks.length} bricks'),
      findsOneWidget,
    );
  });

  testWidgets('typing in search narrows the grid to matches', (tester) async {
    await tester.pumpWidget(_wrap(const BrickDock()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'plate');
    await tester.pumpAndSettle();

    final matching = kStarterBricks.where((b) => b.matches('plate')).toList();
    expect(matching, isNotEmpty);
    expect(find.byType(BrickCatalogCard), findsNWidgets(matching.length));
    for (final brick in matching) {
      expect(find.text(brick.name), findsOneWidget);
    }
    expect(find.text('${matching.length} of ${kStarterBricks.length} bricks'), findsOneWidget);
  });

  testWidgets('search is case-insensitive and matches keywords', (tester) async {
    await tester.pumpWidget(_wrap(const BrickDock()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'RAMP');
    await tester.pumpAndSettle();

    expect(find.text('2 × 2 Slope'), findsOneWidget);
    expect(find.byType(BrickCatalogCard), findsOneWidget);
  });

  testWidgets('no matches shows an empty state, not an empty grid', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const BrickDock()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'nonexistent brick xyz');
    await tester.pumpAndSettle();

    expect(find.byType(BrickCatalogCard), findsNothing);
    expect(find.textContaining('No bricks match'), findsOneWidget);
  });

  testWidgets('clearing the search restores the full list', (tester) async {
    await tester.pumpWidget(_wrap(const BrickDock()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'plate');
    await tester.pumpAndSettle();
    expect(
      find.byType(BrickCatalogCard),
      findsNWidgets(kStarterBricks.where((b) => b.matches('plate')).length),
    );

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.byType(BrickCatalogCard), findsNWidgets(kStarterBricks.length));

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, isEmpty);
  });

  testWidgets('tapping a brick reports it via onBrickSelected', (
    tester,
  ) async {
    final selected = <String>[];
    await tester.pumpWidget(
      _wrap(BrickDock(onBrickSelected: (brick) => selected.add(brick.id))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(kStarterBricks.first.name));
    await tester.pumpAndSettle();

    expect(selected, [kStarterBricks.first.id]);
  });

  testWidgets('a selected card exposes itself as selected to a11y tooling', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(const BrickDock()));
    await tester.pumpAndSettle();

    final firstBrick = kStarterBricks.first;
    final cardFinder = find.ancestor(
      of: find.text(firstBrick.name),
      matching: find.byType(BrickCatalogCard),
    );
    expect(
      tester.getSemantics(cardFinder),
      matchesSemantics(
        label:
            '${firstBrick.name}, ${firstBrick.shape.label}, '
            '${firstBrick.footprintLabel}',
        hasTapAction: true,
        isButton: true,
      ),
    );

    await tester.tap(find.text(firstBrick.name));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(cardFinder),
      matchesSemantics(
        label:
            '${firstBrick.name}, ${firstBrick.shape.label}, '
            '${firstBrick.footprintLabel}',
        hasTapAction: true,
        isButton: true,
        isSelected: true,
      ),
    );

    handle.dispose();
  });
}
