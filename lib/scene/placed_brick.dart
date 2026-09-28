import 'package:vector_math/vector_math_64.dart';

import '../catalog/brick_definition.dart';

/// One brick instance placed in the build scene.
///
/// This is pure data — no rendering state, no Thermion types. It describes
/// *what* is in the scene and *where*; [BrickScene] owns the list of these,
/// and the renderer (see lib/scene/scene_renderer.dart) is just a reflection
/// of it, not the other way around.
class PlacedBrick {
  final String instanceId;
  final BrickDefinition definition;

  /// World position. By convention this is the brick's vertical center, not
  /// its base — see [BrickMeshBuilder] for why.
  final Vector3 position;

  /// Rotation around the vertical (Y) axis, in fixed 90° steps — bricks only
  /// ever face one of 4 cardinal directions, matching how real bricks are
  /// turned when building.
  final int rotationSteps;

  PlacedBrick({
    required this.instanceId,
    required this.definition,
    required this.position,
    this.rotationSteps = 0,
  }) : assert(rotationSteps >= 0 && rotationSteps < 4);

  double get rotationRadians => rotationSteps * (3.141592653589793 / 2);

  PlacedBrick copyWith({Vector3? position, int? rotationSteps}) {
    return PlacedBrick(
      instanceId: instanceId,
      definition: definition,
      position: position ?? this.position,
      rotationSteps: rotationSteps == null
          ? this.rotationSteps
          : rotationSteps % 4,
    );
  }
}
