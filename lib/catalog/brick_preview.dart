import 'package:flutter/material.dart';

import 'brick_definition.dart';

/// A simple, drawn top-down placeholder for a brick: a rounded footprint in
/// the brick's color with one stud per [BrickDefinition.studsX] ×
/// [BrickDefinition.studsY] position. Used until real 3D thumbnails are
/// available from the renderer.
class BrickPreview extends StatelessWidget {
  final BrickDefinition brick;

  const BrickPreview({super.key, required this.brick});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(painter: _BrickPreviewPainter(brick)),
    );
  }
}

class _BrickPreviewPainter extends CustomPainter {
  final BrickDefinition brick;

  _BrickPreviewPainter(this.brick);

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()..color = brick.color;
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final inset = size.shortestSide * 0.08;
    final bodyRect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final radius = Radius.circular(size.shortestSide * 0.08);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, radius);

    // Flatter footprint reads as a plate/tile; a slope tapers to one edge.
    switch (brick.shape) {
      case BrickShape.slope:
        final path = Path()
          ..moveTo(bodyRect.left, bodyRect.bottom)
          ..lineTo(bodyRect.right, bodyRect.bottom)
          ..lineTo(bodyRect.right, bodyRect.top + bodyRect.height * 0.35)
          ..lineTo(bodyRect.left, bodyRect.top)
          ..close();
        canvas.drawPath(path, bodyPaint);
        canvas.drawPath(path, borderPaint);
        break;
      case BrickShape.round:
        canvas.drawOval(bodyRect, bodyPaint);
        canvas.drawOval(bodyRect, borderPaint);
        break;
      case BrickShape.brick:
      case BrickShape.plate:
      case BrickShape.tile:
        canvas.drawRRect(bodyRRect, bodyPaint);
        canvas.drawRRect(bodyRRect, borderPaint);
        break;
    }

    _paintStuds(canvas, bodyRect);
  }

  void _paintStuds(Canvas canvas, Rect bodyRect) {
    if (brick.shape == BrickShape.slope) return;

    final studPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    final studBorderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final cols = brick.studsX;
    final rows = brick.studsY;
    final cellWidth = bodyRect.width / cols;
    final cellHeight = bodyRect.height / rows;
    final studRadius = (cellWidth < cellHeight ? cellWidth : cellHeight) * 0.28;

    for (var col = 0; col < cols; col++) {
      for (var row = 0; row < rows; row++) {
        final center = Offset(
          bodyRect.left + cellWidth * (col + 0.5),
          bodyRect.top + cellHeight * (row + 0.5),
        );
        canvas.drawCircle(center, studRadius, studPaint);
        canvas.drawCircle(center, studRadius, studBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BrickPreviewPainter oldDelegate) =>
      oldDelegate.brick != brick;
}
