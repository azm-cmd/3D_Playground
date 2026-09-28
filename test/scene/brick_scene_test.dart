import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:brick_playground/catalog/brick_catalog.dart';
import 'package:brick_playground/scene/brick_scene.dart';

void main() {
  late BrickScene scene;

  setUp(() {
    scene = BrickScene();
  });

  group('place', () {
    test('adds a brick with the requested definition', () {
      final brick = scene.place(kStarterBricks.first);
      expect(scene.bricks, hasLength(1));
      expect(scene.bricks.single.definition, kStarterBricks.first);
      expect(brick.definition, kStarterBricks.first);
    });

    test('gives every placed brick a unique instance id, even for the same definition', () {
      final a = scene.place(kStarterBricks.first);
      final b = scene.place(kStarterBricks.first);
      final c = scene.place(kStarterBricks.first);
      expect({a.instanceId, b.instanceId, c.instanceId}, hasLength(3));
    });

    test('selects the newly placed brick', () {
      scene.place(kStarterBricks.first);
      final second = scene.place(kStarterBricks[1]);
      expect(scene.selectedInstanceId, second.instanceId);
      expect(scene.selectedBrick, isNotNull);
      expect(scene.selectedBrick!.instanceId, second.instanceId);
    });

    test('does not spawn every brick at the exact same position', () {
      final placed = List.generate(5, (_) => scene.place(kStarterBricks.first));
      final positions = placed.map((b) => b.position).toSet();
      expect(
        positions,
        hasLength(5),
        reason: 'each placement should get a distinct position',
      );
    });

    test('gives every new brick an initial transform with no rotation', () {
      final brick = scene.place(kStarterBricks.first);
      expect(brick.rotationSteps, 0);
    });
  });

  group('select', () {
    test('selects a known instance id', () {
      final brick = scene.place(kStarterBricks.first);
      scene.select(null); // clear the auto-selection from place()
      expect(scene.selectedInstanceId, isNull);

      scene.select(brick.instanceId);
      expect(scene.selectedInstanceId, brick.instanceId);
    });

    test(
      'selecting an unknown id clears the selection instead of throwing',
      () {
        scene.place(kStarterBricks.first);
        scene.select('does-not-exist');
        expect(scene.selectedInstanceId, isNull);
      },
    );

    test('selecting null clears the selection', () {
      scene.place(kStarterBricks.first);
      scene.select(null);
      expect(scene.selectedInstanceId, isNull);
      expect(scene.selectedBrick, isNull);
    });
  });

  group('moveSelectedBy', () {
    test('moves the selected brick by the given delta', () {
      final brick = scene.place(kStarterBricks.first);
      final before = brick.position.clone();

      scene.moveSelectedBy(Vector3(1, 0, -2));

      final after = scene.selectedBrick!.position;
      expect(after, before + Vector3(1, 0, -2));
    });

    test('is a no-op when nothing is selected', () {
      scene.place(kStarterBricks.first);
      scene.select(null);
      expect(() => scene.moveSelectedBy(Vector3(1, 0, 0)), returnsNormally);
      expect(scene.selectedInstanceId, isNull);
    });

    test('only moves the selected brick, not others', () {
      final a = scene.place(kStarterBricks.first);
      final b = scene.place(kStarterBricks[1]); // b is now selected
      final aPositionBefore = scene.bricks
          .firstWhere((x) => x.instanceId == a.instanceId)
          .position;

      scene.moveSelectedBy(Vector3(9, 0, 9));

      final aPositionAfter = scene.bricks
          .firstWhere((x) => x.instanceId == a.instanceId)
          .position;
      final bPositionAfter = scene.bricks
          .firstWhere((x) => x.instanceId == b.instanceId)
          .position;
      expect(aPositionAfter, aPositionBefore);
      expect(bPositionAfter, isNot(equals(b.position)));
    });
  });

  group('rotateSelectedBy', () {
    test('advances rotationSteps and wraps at 4', () {
      scene.place(kStarterBricks.first);
      expect(scene.selectedBrick!.rotationSteps, 0);

      scene.rotateSelectedBy(1);
      expect(scene.selectedBrick!.rotationSteps, 1);

      scene.rotateSelectedBy(1);
      scene.rotateSelectedBy(1);
      scene.rotateSelectedBy(1);
      expect(
        scene.selectedBrick!.rotationSteps,
        0,
        reason: '4 steps of 90° is a full turn',
      );
    });

    test('is a no-op when nothing is selected', () {
      scene.place(kStarterBricks.first);
      scene.select(null);
      expect(() => scene.rotateSelectedBy(1), returnsNormally);
    });
  });

  group('deleteSelected', () {
    test('removes the selected brick and clears the selection', () {
      final brick = scene.place(kStarterBricks.first);
      final result = scene.deleteSelected();
      expect(result, isTrue);
      expect(scene.bricks, isEmpty);
      expect(scene.selectedInstanceId, isNull);
      expect(
        scene.bricks.any((b) => b.instanceId == brick.instanceId),
        isFalse,
      );
    });

    test('only removes the selected brick, leaving others in place', () {
      final a = scene.place(kStarterBricks.first);
      scene.place(kStarterBricks[1]); // selected
      scene.deleteSelected();
      expect(scene.bricks, hasLength(1));
      expect(scene.bricks.single.instanceId, a.instanceId);
    });

    test('returns false and is a no-op when nothing is selected', () {
      scene.place(kStarterBricks.first);
      scene.select(null);
      final result = scene.deleteSelected();
      expect(result, isFalse);
      expect(scene.bricks, hasLength(1));
    });
  });
}
