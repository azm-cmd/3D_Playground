import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import '../catalog/brick_definition.dart';
import 'brick_scene.dart';
import 'placed_brick.dart';

/// Thin Flutter glue around [BrickScene]: same source of truth, just with
/// change notification so widgets (the dock, the selection toolbar, the
/// renderer sync) can react to it.
class SceneController extends ChangeNotifier {
  final BrickScene _scene = BrickScene();

  List<PlacedBrick> get bricks => _scene.bricks;

  String? get selectedInstanceId => _scene.selectedInstanceId;

  PlacedBrick? get selectedBrick => _scene.selectedBrick;

  bool get hasSelection => _scene.selectedInstanceId != null;

  PlacedBrick place(BrickDefinition definition) {
    final brick = _scene.place(definition);
    notifyListeners();
    return brick;
  }

  void select(String? instanceId) {
    if (instanceId == _scene.selectedInstanceId) return;
    _scene.select(instanceId);
    notifyListeners();
  }

  void moveSelectedBy(Vector3 delta) {
    if (!hasSelection) return;
    _scene.moveSelectedBy(delta);
    notifyListeners();
  }

  void rotateSelectedBy90() {
    if (!hasSelection) return;
    _scene.rotateSelectedBy(1);
    notifyListeners();
  }

  void deleteSelected() {
    if (_scene.deleteSelected()) {
      notifyListeners();
    }
  }
}
