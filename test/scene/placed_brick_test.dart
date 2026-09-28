import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:brick_playground/catalog/brick_catalog.dart';
import 'package:brick_playground/scene/placed_brick.dart';

void main() {
  PlacedBrick brickAt(Vector3 position, {int rotationSteps = 0}) => PlacedBrick(
    instanceId: 'test',
    definition: kStarterBricks.first,
    position: position,
    rotationSteps: rotationSteps,
  );

  group('PlacedBrick', () {
    test('defaults to no rotation', () {
      final brick = brickAt(Vector3.zero());
      expect(brick.rotationSteps, 0);
      expect(brick.rotationRadians, 0);
    });

    test('rotationRadians reflects 90° per step', () {
      expect(
        brickAt(Vector3.zero(), rotationSteps: 1).rotationRadians,
        closeTo(math.pi / 2, 1e-9),
      );
      expect(
        brickAt(Vector3.zero(), rotationSteps: 2).rotationRadians,
        closeTo(math.pi, 1e-9),
      );
      expect(
        brickAt(Vector3.zero(), rotationSteps: 3).rotationRadians,
        closeTo(3 * math.pi / 2, 1e-9),
      );
    });

    group('copyWith', () {
      test('with no arguments returns an equivalent brick', () {
        final original = brickAt(Vector3(1, 0, 2), rotationSteps: 1);
        final copy = original.copyWith();
        expect(copy.instanceId, original.instanceId);
        expect(copy.definition, original.definition);
        expect(copy.position, original.position);
        expect(copy.rotationSteps, original.rotationSteps);
      });

      test('updates only the position when given one', () {
        final original = brickAt(Vector3(1, 0, 2), rotationSteps: 2);
        final moved = original.copyWith(position: Vector3(5, 0, -3));
        expect(moved.position, Vector3(5, 0, -3));
        expect(moved.rotationSteps, 2);
        // The original is untouched — this is a value update, not a mutation.
        expect(original.position, Vector3(1, 0, 2));
      });

      test('wraps rotationSteps into the 0..3 range', () {
        final brick = brickAt(Vector3.zero());
        expect(brick.copyWith(rotationSteps: 4).rotationSteps, 0);
        expect(brick.copyWith(rotationSteps: 5).rotationSteps, 1);
        expect(brick.copyWith(rotationSteps: -1).rotationSteps, 3);
      });
    });
  });
}
