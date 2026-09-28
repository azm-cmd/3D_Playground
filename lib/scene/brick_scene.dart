import 'package:vector_math/vector_math_64.dart';

import '../catalog/brick_definition.dart';
import 'placed_brick.dart';

/// Pure, renderer-agnostic state for the build scene: which bricks are
/// placed, where, and which one (if any) is selected.
///
/// This is the source of truth for what's in the 3D scene. The Flutter
/// widget tree and the Thermion renderer both just reflect this state on
/// change — neither of them owns it.
class BrickScene {
  final List<PlacedBrick> _bricks = [];
  String? _selectedInstanceId;
  int _nextInstanceSeq = 0;

  /// Horizontal spacing between auto-placed bricks, and how many go in a
  /// row before wrapping — keeps newly placed bricks from stacking on top
  /// of each other while staying deterministic (no camera/raycast needed).
  static const double placementSpacing = 1.6;
  static const int placementColumns = 4;

  List<PlacedBrick> get bricks => List.unmodifiable(_bricks);

  String? get selectedInstanceId => _selectedInstanceId;

  PlacedBrick? get selectedBrick {
    final id = _selectedInstanceId;
    if (id == null) return null;
    for (final brick in _bricks) {
      if (brick.instanceId == id) return brick;
    }
    return null;
  }

  /// Places a new instance of [definition], at a position that spreads
  /// bricks out rather than stacking them at the origin, and selects it.
  PlacedBrick place(BrickDefinition definition) {
    final index = _bricks.length;
    final col = index % placementColumns;
    final row = index ~/ placementColumns;
    final position = Vector3(
      (col - (placementColumns - 1) / 2) * placementSpacing,
      0,
      row * placementSpacing,
    );
    final brick = PlacedBrick(
      instanceId: 'brick_${_nextInstanceSeq++}',
      definition: definition,
      position: position,
    );
    _bricks.add(brick);
    _selectedInstanceId = brick.instanceId;
    return brick;
  }

  /// Selects the brick with [instanceId]. Passing null (or an id that isn't
  /// in the scene) clears the selection.
  void select(String? instanceId) {
    _selectedInstanceId =
        instanceId != null && _bricks.any((b) => b.instanceId == instanceId)
        ? instanceId
        : null;
  }

  /// Moves the selected brick by [delta] in world space. No-op if nothing
  /// is selected.
  void moveSelectedBy(Vector3 delta) {
    _updateSelected((b) => b.copyWith(position: b.position + delta));
  }

  /// Rotates the selected brick by [steps] × 90°. No-op if nothing is
  /// selected.
  void rotateSelectedBy(int steps) {
    _updateSelected((b) => b.copyWith(rotationSteps: b.rotationSteps + steps));
  }

  /// Removes the selected brick and clears the selection. Returns whether
  /// there was a selection to delete.
  bool deleteSelected() {
    final id = _selectedInstanceId;
    if (id == null) return false;
    _bricks.removeWhere((b) => b.instanceId == id);
    _selectedInstanceId = null;
    return true;
  }

  void _updateSelected(PlacedBrick Function(PlacedBrick current) update) {
    final id = _selectedInstanceId;
    if (id == null) return;
    final index = _bricks.indexWhere((b) => b.instanceId == id);
    if (index == -1) return;
    _bricks[index] = update(_bricks[index]);
  }
}
