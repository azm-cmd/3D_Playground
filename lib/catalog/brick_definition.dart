import 'package:flutter/material.dart';

/// The broad family a catalog brick belongs to. Drives both the placeholder
/// preview drawing and the label shown under a brick's name.
enum BrickShape { brick, plate, slope, round, tile }

extension BrickShapeLabel on BrickShape {
  String get label {
    switch (this) {
      case BrickShape.brick:
        return 'Brick';
      case BrickShape.plate:
        return 'Plate';
      case BrickShape.slope:
        return 'Slope';
      case BrickShape.round:
        return 'Round brick';
      case BrickShape.tile:
        return 'Tile';
    }
  }
}

/// A single entry in the brick catalog.
///
/// This is intentionally data-only: it describes what a brick *is*, not how
/// it is placed, selected, or snapped in a scene. Growing the catalog means
/// adding more [BrickDefinition] values, not writing more UI code.
@immutable
class BrickDefinition {
  final String id;
  final String name;
  final BrickShape shape;

  /// Footprint in studs, e.g. a "2×4 Brick" is [studsX] = 2, [studsY] = 4.
  final int studsX;
  final int studsY;

  /// Height in standard brick units (a full brick is 1.0, a plate is 1 / 3).
  final double heightUnits;

  final Color color;

  /// Extra search terms beyond the name/subtitle/shape (synonyms, category
  /// words) so search can find a brick by more than its exact label.
  final List<String> keywords;

  const BrickDefinition({
    required this.id,
    required this.name,
    required this.shape,
    required this.studsX,
    required this.studsY,
    required this.heightUnits,
    required this.color,
    this.keywords = const [],
  });

  /// e.g. "2 × 4 studs".
  String get footprintLabel => '$studsX × $studsY studs';

  /// Whether this brick matches a query already run through
  /// [normalizeForSearch]. Kept as a pure function so it's testable
  /// without building any widgets.
  bool matches(String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;
    final haystack = normalizeForSearch(
      <String>[name, shape.label, footprintLabel, ...keywords].join(' '),
    );
    if (haystack.contains(normalizedQuery)) return true;

    // Labels are spaced out ("2 x 4 brick"), but a compact query like
    // "2x4" is at least as natural to type — compare with spaces
    // stripped from both sides as a fallback.
    final compactHaystack = haystack.replaceAll(' ', '');
    final compactQuery = normalizedQuery.replaceAll(' ', '');
    return compactHaystack.contains(compactQuery);
  }
}

/// Normalizes free text for search matching: trims, lowercases, and maps
/// the "×" used in names and footprint labels (e.g. "2 × 4 Brick") to a
/// plain "x" so a query typed with an ordinary keyboard "x" (e.g. "2x4")
/// still matches.
String normalizeForSearch(String value) =>
    value.trim().toLowerCase().replaceAll('×', 'x');
