import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:brick_playground/catalog/brick_catalog.dart';
import 'package:brick_playground/scene/scene_controller.dart';

void main() {
  late SceneController controller;
  late int notifyCount;

  setUp(() {
    controller = SceneController();
    notifyCount = 0;
    controller.addListener(() => notifyCount++);
  });

  tearDown(() {
    controller.dispose();
  });

  test('starts empty with nothing selected', () {
    expect(controller.bricks, isEmpty);
    expect(controller.hasSelection, isFalse);
    expect(controller.selectedBrick, isNull);
  });

  test('place adds a brick, selects it, and notifies listeners', () {
    final brick = controller.place(kStarterBricks.first);
    expect(controller.bricks, hasLength(1));
    expect(controller.selectedInstanceId, brick.instanceId);
    expect(controller.hasSelection, isTrue);
    expect(notifyCount, 1);
  });

  test(
    'select notifies listeners only when the selection actually changes',
    () {
      final brick = controller.place(kStarterBricks.first);
      notifyCount = 0;

      controller.select(brick.instanceId); // already selected: no-op
      expect(notifyCount, 0);

      controller.select(null);
      expect(controller.hasSelection, isFalse);
      expect(notifyCount, 1);

      controller.select(null); // already deselected: no-op
      expect(notifyCount, 1);
    },
  );

  test(
    'moveSelectedBy updates position and notifies only with a selection',
    () {
      controller.place(kStarterBricks.first);
      final before = controller.selectedBrick!.position.clone();
      notifyCount = 0;

      controller.moveSelectedBy(Vector3(1, 0, 1));
      expect(controller.selectedBrick!.position, before + Vector3(1, 0, 1));
      expect(notifyCount, 1);

      controller.select(null);
      notifyCount = 0;
      controller.moveSelectedBy(Vector3(1, 0, 1));
      expect(
        notifyCount,
        0,
        reason: 'nothing selected, nothing to move or notify about',
      );
    },
  );

  test(
    'rotateSelectedBy90 advances rotation and notifies only with a selection',
    () {
      controller.place(kStarterBricks.first);
      notifyCount = 0;

      controller.rotateSelectedBy90();
      expect(controller.selectedBrick!.rotationSteps, 1);
      expect(notifyCount, 1);

      controller.select(null);
      notifyCount = 0;
      controller.rotateSelectedBy90();
      expect(notifyCount, 0);
    },
  );

  test('deleteSelected removes the brick, clears selection, and notifies', () {
    controller.place(kStarterBricks.first);
    notifyCount = 0;

    controller.deleteSelected();
    expect(controller.bricks, isEmpty);
    expect(controller.hasSelection, isFalse);
    expect(notifyCount, 1);
  });

  test('deleteSelected with no selection is a no-op and does not notify', () {
    controller.place(kStarterBricks.first);
    controller.select(null);
    notifyCount = 0;

    controller.deleteSelected();
    expect(controller.bricks, hasLength(1));
    expect(notifyCount, 0);
  });

  test('placing multiple bricks keeps each independently selectable', () {
    final a = controller.place(kStarterBricks.first);
    final b = controller.place(kStarterBricks[1]);
    expect(controller.bricks, hasLength(2));

    controller.select(a.instanceId);
    expect(controller.selectedBrick!.instanceId, a.instanceId);

    controller.select(b.instanceId);
    expect(controller.selectedBrick!.instanceId, b.instanceId);
  });
}
