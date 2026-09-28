import 'package:flutter/material.dart' show Color;
import 'package:thermion_flutter/thermion_flutter.dart';

import 'brick_mesh_builder.dart';
import 'placed_brick.dart';

/// Reflects a [BrickScene] snapshot into the live Thermion viewer: creates
/// an entity per placed brick, keeps its transform and selection highlight
/// in sync, and removes entities for bricks that are gone.
///
/// This is the only place that owns Thermion resources for placed bricks —
/// neither the scene model nor the widget tree touches a [ThermionAsset]
/// directly.
class SceneRenderer {
  final ThermionViewer viewer;
  final Map<String, _RenderedBrick> _rendered = {};
  final Map<ThermionEntity, String> _entityToInstanceId = {};

  SceneRenderer(this.viewer);

  /// The placed-brick instance id for a picked [entity], or null if the
  /// entity isn't a rendered brick (e.g. a background/ground hit).
  String? instanceIdForEntity(ThermionEntity entity) =>
      _entityToInstanceId[entity];

  /// Reconciles the live scene with [bricks], highlighting
  /// [selectedInstanceId] if set.
  Future<void> sync(
    List<PlacedBrick> bricks,
    String? selectedInstanceId,
  ) async {
    final currentIds = bricks.map((b) => b.instanceId).toSet();

    final staleIds = _rendered.keys
        .where((id) => !currentIds.contains(id))
        .toList();
    for (final id in staleIds) {
      final rendered = _rendered.remove(id);
      if (rendered == null) continue;
      _entityToInstanceId.remove(rendered.asset.entity);
      await viewer.destroyAsset(rendered.asset);
    }

    for (final brick in bricks) {
      final rendered = await _ensureRendered(brick);
      final isSelected = brick.instanceId == selectedInstanceId;
      final color = isSelected
          ? _highlighted(brick.definition.color)
          : brick.definition.color;
      await rendered.material.setBaseColorFactor(
        color.r,
        color.g,
        color.b,
        color.a,
      );
      await rendered.asset.setTransform(_transformFor(brick));
    }
  }

  Future<_RenderedBrick> _ensureRendered(PlacedBrick brick) async {
    final existing = _rendered[brick.instanceId];
    if (existing != null) return existing;

    final material = UbershaderMaterialInstance(
      await viewer.app.createUbershaderMaterialInstance(),
    );
    final geometry = BrickMeshBuilder.build(brick.definition);
    final asset = await viewer.createGeometry(
      geometry,
      materialInstances: [material.materialInstance],
    );
    final rendered = _RenderedBrick(asset: asset, material: material);
    _rendered[brick.instanceId] = rendered;
    _entityToInstanceId[asset.entity] = brick.instanceId;
    return rendered;
  }

  Matrix4 _transformFor(PlacedBrick brick) {
    return Matrix4.identity()
      ..translateByVector3(brick.position)
      ..rotateY(brick.rotationRadians);
  }

  /// A subtle, per-brick selection cue: the brick's own color, lightened —
  /// deliberately not a generic outline (Thermion has no simple, robust
  /// selection-outline primitive to reach for here).
  Color _highlighted(Color base) =>
      Color.lerp(base, const Color(0xFFFFFFFF), 0.35)!;

  /// Releases every rendered brick's Thermion resources. Call when the
  /// owning viewer is being torn down.
  Future<void> dispose() async {
    for (final rendered in _rendered.values) {
      await viewer.destroyAsset(rendered.asset);
    }
    _rendered.clear();
    _entityToInstanceId.clear();
  }
}

class _RenderedBrick {
  final ThermionAsset asset;
  final UbershaderMaterialInstance material;

  _RenderedBrick({required this.asset, required this.material});
}
