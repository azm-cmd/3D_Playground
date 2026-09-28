// Pure-logic tests for catalog search filtering. These don't pump any
// widgets, so they exercise the same matching logic the dock UI uses
// without depending on rendering.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brick_playground/catalog/brick_catalog.dart';
import 'package:brick_playground/catalog/brick_definition.dart';

void main() {
  group('kStarterBricks', () {
    test('has between 5 and 10 entries with unique ids', () {
      expect(kStarterBricks.length, inInclusiveRange(5, 10));
      final ids = kStarterBricks.map((b) => b.id).toSet();
      expect(ids.length, kStarterBricks.length);
    });

    test('every brick has a positive footprint and height', () {
      for (final brick in kStarterBricks) {
        expect(brick.studsX, greaterThan(0));
        expect(brick.studsY, greaterThan(0));
        expect(brick.heightUnits, greaterThan(0));
        expect(brick.name, isNotEmpty);
      }
    });
  });

  group('filterBricks', () {
    test('empty query returns the full list, unfiltered', () {
      expect(filterBricks(kStarterBricks, ''), kStarterBricks);
      expect(filterBricks(kStarterBricks, '   '), kStarterBricks);
    });

    test('matches by exact name, case-insensitively', () {
      final results = filterBricks(kStarterBricks, '2 X 4 bRiCk');
      expect(results.map((b) => b.id), contains('brick_2x4'));
    });

    test('an ASCII "x" matches the "×" used in names and labels', () {
      // Names/labels are written with a real multiplication sign ("2 × 4
      // Brick"), but a normal keyboard search is typed as "2x4".
      final results = filterBricks(kStarterBricks, '2x4');
      expect(results.map((b) => b.id), containsAll(['brick_2x4', 'plate_2x4']));
    });

    test('matches by shape label', () {
      final results = filterBricks(kStarterBricks, 'plate');
      expect(results, isNotEmpty);
      expect(results.every((b) => b.shape == BrickShape.plate), isTrue);
    });

    test('matches by keyword not present in the name', () {
      final results = filterBricks(kStarterBricks, 'ramp');
      expect(results.map((b) => b.id), contains('slope_2x2'));
    });

    test('matches by footprint text', () {
      final results = filterBricks(kStarterBricks, '1 × 1');
      expect(results, isNotEmpty);
      expect(results.every((b) => b.studsX == 1 && b.studsY == 1), isTrue);
    });

    test('unmatched query returns an empty list', () {
      expect(filterBricks(kStarterBricks, 'nonexistent brick xyz'), isEmpty);
    });

    test('leading/trailing whitespace is ignored', () {
      final trimmed = filterBricks(kStarterBricks, 'brick');
      final padded = filterBricks(kStarterBricks, '  brick  ');
      expect(padded, trimmed);
    });
  });

  group('BrickDefinition.matches', () {
    const brick = BrickDefinition(
      id: 'test',
      name: '2 × 4 Brick',
      shape: BrickShape.brick,
      studsX: 2,
      studsY: 4,
      heightUnits: 1.0,
      color: Color(0xFFFF0000),
      keywords: ['classic'],
    );

    test('an already-empty normalized query matches anything', () {
      expect(brick.matches(''), isTrue);
    });

    test('expects its query pre-normalized (lowercase, trimmed)', () {
      expect(brick.matches('classic'), isTrue);
      expect(brick.matches('CLASSIC'), isFalse);
    });
  });
}
