import 'dart:math' as math;

import 'package:thermion_flutter/thermion_flutter.dart';

import '../catalog/brick_definition.dart';

/// Builds a single procedural [Geometry] for a [BrickDefinition] — the
/// brick's body plus its top studs combined into one mesh, so each placed
/// brick is exactly one Thermion entity (simpler picking: one entity maps
/// to exactly one placed-brick instance, no sub-part bookkeeping).
///
/// No real 3D assets exist yet, so this deliberately stays simple: flat
/// -shaded boxes/wedges/a low-poly cylinder, verified by hand for
/// correct (outward-facing, CCW) winding rather than by eye, since this
/// environment has no way to actually view a render.
class BrickMeshBuilder {
  BrickMeshBuilder._();

  /// World units between adjacent stud centers — also a brick's footprint
  /// unit (a "2 × 4" brick is 2 × [studPitch] wide by 4 × [studPitch] deep).
  static const double studPitch = 1.0;

  /// Height of a full brick (a plate, at heightUnits = 1/3, is a third of
  /// this).
  static const double unitHeight = 1.2;

  /// Footprint is shrunk slightly so adjacent bricks read as visually
  /// distinct objects even before real snapping exists.
  static const double footprintInset = 0.96;

  static const double studHeight = 0.22;
  static const double studRadiusFactor = 0.28;
  static const int cylinderSegments = 16;

  static Geometry build(BrickDefinition brick) {
    final mesh = _MeshBuilder();
    final width = brick.studsX * studPitch * footprintInset;
    final depth = brick.studsY * studPitch * footprintInset;
    final height = brick.heightUnits * unitHeight;

    // The mesh is centered vertically on the brick's placement position
    // (rather than resting on a y = 0 base) purely so a freshly placed
    // brick sits well-framed in the default camera view. Nothing here
    // depends on a "ground" yet — stacking/gravity is out of scope for
    // this phase.
    final bottom = -height / 2;
    final top = height / 2;

    switch (brick.shape) {
      case BrickShape.slope:
        _addWedge(
          mesh,
          width: width,
          height: height,
          depth: depth,
          baseY: bottom,
        );
        break;
      case BrickShape.round:
        _addCylinder(
          mesh,
          radius: width / 2,
          height: height,
          baseY: bottom,
          segments: cylinderSegments,
        );
        _addStuds(mesh, brick, top);
        break;
      case BrickShape.brick:
      case BrickShape.plate:
        _addBox(
          mesh,
          width: width,
          height: height,
          depth: depth,
          baseY: bottom,
        );
        _addStuds(mesh, brick, top);
        break;
      case BrickShape.tile:
        _addBox(
          mesh,
          width: width,
          height: height,
          depth: depth,
          baseY: bottom,
        );
        break;
    }

    return mesh.build();
  }

  static void _addStuds(_MeshBuilder mesh, BrickDefinition brick, double topY) {
    final studSize = studPitch * studRadiusFactor * 2;
    final startX = -(brick.studsX - 1) * studPitch / 2;
    final startZ = -(brick.studsY - 1) * studPitch / 2;
    for (var col = 0; col < brick.studsX; col++) {
      for (var row = 0; row < brick.studsY; row++) {
        _addBox(
          mesh,
          width: studSize,
          height: studHeight,
          depth: studSize,
          baseY: topY,
          centerX: startX + col * studPitch,
          centerZ: startZ + row * studPitch,
        );
      }
    }
  }

  /// An axis-aligned box spanning [baseY, baseY + height], centered at
  /// ([centerX], [centerZ]) in the XZ plane.
  static void _addBox(
    _MeshBuilder mesh, {
    required double width,
    required double height,
    required double depth,
    required double baseY,
    double centerX = 0,
    double centerZ = 0,
  }) {
    final hw = width / 2;
    final hd = depth / 2;
    final x0 = centerX - hw, x1 = centerX + hw;
    final y0 = baseY, y1 = baseY + height;
    final z0 = centerZ - hd, z1 = centerZ + hd;

    final a = _V(x0, y0, z0); // bottom, front, left
    final b = _V(x1, y0, z0); // bottom, front, right
    final c = _V(x1, y0, z1); // bottom, back, right
    final d = _V(x0, y0, z1); // bottom, back, left
    final e = _V(x0, y1, z0); // top, front, left
    final f = _V(x1, y1, z0); // top, front, right
    final g = _V(x1, y1, z1); // top, back, right
    final h = _V(x0, y1, z1); // top, back, left

    mesh.addQuad(a, b, c, d); // bottom, outward -Y
    mesh.addQuad(e, h, g, f); // top, outward +Y
    mesh.addQuad(a, e, f, b); // front, outward -Z
    mesh.addQuad(d, c, g, h); // back, outward +Z
    mesh.addQuad(a, d, h, e); // left, outward -X
    mesh.addQuad(b, f, g, c); // right, outward +X
  }

  /// A wedge that tapers from full height at the back (+Z) to zero height
  /// at the front (-Z) — used for [BrickShape.slope]. Studless, matching
  /// the 2D catalog preview.
  static void _addWedge(
    _MeshBuilder mesh, {
    required double width,
    required double height,
    required double depth,
    required double baseY,
  }) {
    final hw = width / 2;
    final hd = depth / 2;
    final x0 = -hw, x1 = hw;
    final y0 = baseY, y1 = baseY + height;
    final z0 = -hd, z1 = hd;

    final a = _V(x0, y0, z0); // bottom, front, left
    final b = _V(x1, y0, z0); // bottom, front, right
    final c = _V(x1, y0, z1); // bottom, back, right
    final d = _V(x0, y0, z1); // bottom, back, left
    final e = _V(x0, y1, z1); // top, back, left
    final f = _V(x1, y1, z1); // top, back, right

    mesh.addQuad(a, b, c, d); // bottom, outward -Y
    mesh.addQuad(d, c, f, e); // back, outward +Z
    mesh.addQuad(a, e, f, b); // slanted top, outward (+Y, -Z)-ish
    mesh.addTriangle(a, d, e); // left, outward -X
    mesh.addTriangle(b, f, c); // right, outward +X
  }

  /// A low-poly cylinder (an N-gon prism) spanning [baseY, baseY + height]
  /// — used for [BrickShape.round].
  static void _addCylinder(
    _MeshBuilder mesh, {
    required double radius,
    required double height,
    required double baseY,
    required int segments,
  }) {
    final bottomCenter = _V(0, baseY, 0);
    final topCenter = _V(0, baseY + height, 0);
    final bottomRing = <_V>[];
    final topRing = <_V>[];
    for (var i = 0; i < segments; i++) {
      final angle = 2 * math.pi * i / segments;
      final dx = math.cos(angle) * radius;
      final dz = math.sin(angle) * radius;
      bottomRing.add(_V(dx, baseY, dz));
      topRing.add(_V(dx, baseY + height, dz));
    }
    for (var i = 0; i < segments; i++) {
      final next = (i + 1) % segments;
      mesh.addQuad(bottomRing[i], topRing[i], topRing[next], bottomRing[next]);
      mesh.addTriangle(bottomCenter, bottomRing[i], bottomRing[next]);
      mesh.addTriangle(topCenter, topRing[next], topRing[i]);
    }
  }
}

/// A plain (x, y, z) tuple — kept separate from vector_math's `Vector3` here
/// so this file has no dependency beyond dart:math/dart:typed_data and
/// Thermion's `Geometry` type.
class _V {
  final double x, y, z;
  const _V(this.x, this.y, this.z);

  _V operator -(_V other) => _V(x - other.x, y - other.y, z - other.z);
}

_V _cross(_V a, _V b) =>
    _V(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x);

double _length(_V v) => math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);

/// Accumulates flat-shaded triangles into flat vertex/normal/index buffers.
/// Each triangle gets its own 3 vertices (no sharing) so every face reads as
/// a distinct flat facet, which suits blocky brick geometry and sidesteps
/// having to compute smoothed vertex normals.
class _MeshBuilder {
  final List<double> _positions = [];
  final List<double> _normals = [];
  final List<int> _indices = [];

  void addTriangle(_V a, _V b, _V c) {
    var normal = _cross(b - a, c - a);
    final len = _length(normal);
    if (len > 0) {
      normal = _V(normal.x / len, normal.y / len, normal.z / len);
    }
    final start = _positions.length ~/ 3;
    for (final v in [a, b, c]) {
      _positions.addAll([v.x, v.y, v.z]);
      _normals.addAll([normal.x, normal.y, normal.z]);
    }
    _indices.addAll([start, start + 1, start + 2]);
  }

  /// [a], [b], [c], [d] must be given in CCW order as viewed from the
  /// outward (front) side of the face.
  void addQuad(_V a, _V b, _V c, _V d) {
    addTriangle(a, b, c);
    addTriangle(a, c, d);
  }

  Geometry build() {
    return Geometry(
      Float32List.fromList(_positions),
      Uint16List.fromList(_indices),
      normals: Float32List.fromList(_normals),
    );
  }
}
