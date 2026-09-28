import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import 'scene_controller.dart';

/// World units moved per nudge (toolbar button press or arrow-key press).
const double kBrickMoveStep = 0.5;

/// The contextual controls for the currently selected brick: move (as a
/// compact D-pad), rotate 90°, and delete.
///
/// Deliberately not in-viewport drag/gizmo manipulation — see the Phase 3
/// summary for why: ViewerWidget's ORBIT manipulator already owns
/// single-finger/mouse drag for the camera, and there's no built-in gizmo
/// integration to reach for instead. Discrete controls sidestep that
/// conflict entirely and work identically on touch and mouse.
class SelectionToolbar extends StatelessWidget {
  final SceneController controller;

  const SelectionToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final brick = controller.selectedBrick;
    if (brick == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                brick.definition.name,
                style: theme.textTheme.labelLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _MoveDPad(controller: controller),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Rotate 90°',
              icon: const Icon(Icons.rotate_right),
              onPressed: controller.rotateSelectedBy90,
            ),
            IconButton(
              tooltip: 'Delete brick',
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: controller.deleteSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveDPad extends StatelessWidget {
  final SceneController controller;

  const _MoveDPad({required this.controller});

  void _nudge(double dx, double dz) {
    controller.moveSelectedBy(Vector3(dx, 0, dz));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Move selected brick',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NudgeButton(
            icon: Icons.arrow_upward,
            tooltip: 'Move away',
            onPressed: () => _nudge(0, -kBrickMoveStep),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NudgeButton(
                icon: Icons.arrow_back,
                tooltip: 'Move left',
                onPressed: () => _nudge(-kBrickMoveStep, 0),
              ),
              const SizedBox(width: 36, height: 36),
              _NudgeButton(
                icon: Icons.arrow_forward,
                tooltip: 'Move right',
                onPressed: () => _nudge(kBrickMoveStep, 0),
              ),
            ],
          ),
          _NudgeButton(
            icon: Icons.arrow_downward,
            tooltip: 'Move closer',
            onPressed: () => _nudge(0, kBrickMoveStep),
          ),
        ],
      ),
    );
  }
}

class _NudgeButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _NudgeButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        iconSize: 18,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }
}
