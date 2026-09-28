import 'package:flutter/material.dart';

import 'brick_definition.dart';

/// The starter catalog: a small, hand-picked set of common brick types.
///
/// This list is the seam the catalog is meant to grow through later — new
/// bricks are added here as data, without touching the dock UI.
const List<BrickDefinition> kStarterBricks = [
  BrickDefinition(
    id: 'brick_2x4',
    name: '2 × 4 Brick',
    shape: BrickShape.brick,
    studsX: 2,
    studsY: 4,
    heightUnits: 1.0,
    color: Color(0xFFD01012),
    keywords: ['classic', 'basic', 'red'],
  ),
  BrickDefinition(
    id: 'brick_2x2',
    name: '2 × 2 Brick',
    shape: BrickShape.brick,
    studsX: 2,
    studsY: 2,
    heightUnits: 1.0,
    color: Color(0xFF1B58A3),
    keywords: ['classic', 'basic', 'blue', 'square'],
  ),
  BrickDefinition(
    id: 'brick_1x1',
    name: '1 × 1 Brick',
    shape: BrickShape.brick,
    studsX: 1,
    studsY: 1,
    heightUnits: 1.0,
    color: Color(0xFFF2C61F),
    keywords: ['classic', 'basic', 'yellow', 'small', 'single stud'],
  ),
  BrickDefinition(
    id: 'brick_1x2',
    name: '1 × 2 Brick',
    shape: BrickShape.brick,
    studsX: 1,
    studsY: 2,
    heightUnits: 1.0,
    color: Color(0xFF1B8A3C),
    keywords: ['classic', 'basic', 'green'],
  ),
  BrickDefinition(
    id: 'brick_1x4',
    name: '1 × 4 Brick',
    shape: BrickShape.brick,
    studsX: 1,
    studsY: 4,
    heightUnits: 1.0,
    color: Color(0xFFE87A0F),
    keywords: ['classic', 'basic', 'orange', 'long'],
  ),
  BrickDefinition(
    id: 'plate_2x4',
    name: '2 × 4 Plate',
    shape: BrickShape.plate,
    studsX: 2,
    studsY: 4,
    heightUnits: 1 / 3,
    color: Color(0xFFEEEEEE),
    keywords: ['flat', 'thin', 'white'],
  ),
  BrickDefinition(
    id: 'plate_1x2',
    name: '1 × 2 Plate',
    shape: BrickShape.plate,
    studsX: 1,
    studsY: 2,
    heightUnits: 1 / 3,
    color: Color(0xFF2B2B2B),
    keywords: ['flat', 'thin', 'black'],
  ),
  BrickDefinition(
    id: 'slope_2x2',
    name: '2 × 2 Slope',
    shape: BrickShape.slope,
    studsX: 2,
    studsY: 2,
    heightUnits: 1.0,
    color: Color(0xFF1B58A3),
    keywords: ['roof', 'angled', 'ramp', 'blue'],
  ),
  BrickDefinition(
    id: 'round_1x1',
    name: '1 × 1 Round Brick',
    shape: BrickShape.round,
    studsX: 1,
    studsY: 1,
    heightUnits: 1.0,
    color: Color(0xFFD01012),
    keywords: ['cylinder', 'circular', 'red', 'small'],
  ),
];

/// Filters [kStarterBricks] (or any brick list) by a free-text [query].
///
/// Pure and side-effect free so it can be unit tested directly, without
/// pumping any widgets.
List<BrickDefinition> filterBricks(List<BrickDefinition> bricks, String query) {
  final normalized = normalizeForSearch(query);
  if (normalized.isEmpty) return bricks;
  return bricks.where((brick) => brick.matches(normalized)).toList();
}
