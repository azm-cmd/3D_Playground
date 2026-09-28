import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thermion_flutter/thermion_flutter.dart' hide KeyEvent;

import 'catalog/brick_definition.dart';
import 'catalog/brick_dock.dart';
import 'scene/scene_controller.dart';
import 'scene/scene_renderer.dart';
import 'scene/selection_toolbar.dart';

/// Below this width the brick dock lives in a pull-up tray; at or above it,
/// it docks permanently beside the viewport (roughly phone vs. iPad width).
const double _wideLayoutBreakpoint = 700;

/// Phase 1 validated the Thermion/Filament renderer embedding. Phase 2 added
/// the data-driven brick catalog and its browse/search dock (lib/catalog/).
///
/// Phase 3 connects the two: the dock's "place" action now creates a real
/// brick in the 3D scene (lib/scene/), which the user can select, move,
/// rotate, and delete. lib/scene/brick_scene.dart is the renderer-agnostic
/// source of truth for what's placed; lib/scene/scene_renderer.dart is the
/// only thing that reflects it into Thermion. The widget tree here just
/// wires user input (taps, dock selections, toolbar buttons) to the scene
/// controller, and lets the two sync layers react to it.
void main() {
  runApp(const BrickPlaygroundApp());
}

class BrickPlaygroundApp extends StatelessWidget {
  const BrickPlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brick Playground',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const BuildScreen(),
    );
  }
}

class BuildScreen extends StatefulWidget {
  const BuildScreen({super.key});

  @override
  State<BuildScreen> createState() => _BuildScreenState();
}

class _BuildScreenState extends State<BuildScreen> {
  final SceneController _sceneController = SceneController();
  final FocusNode _viewportFocusNode = FocusNode(debugLabel: 'viewport');

  ThermionViewer? _viewer;
  SceneRenderer? _renderer;

  @override
  void initState() {
    super.initState();
    _sceneController.addListener(_onSceneChanged);
  }

  @override
  void dispose() {
    _sceneController.removeListener(_onSceneChanged);
    _sceneController.dispose();
    _viewportFocusNode.dispose();
    unawaited(_renderer?.dispose());
    super.dispose();
  }

  void _onSceneChanged() {
    final renderer = _renderer;
    if (renderer == null) return;
    unawaited(
      renderer.sync(
        _sceneController.bricks,
        _sceneController.selectedInstanceId,
      ),
    );
  }

  Future<void> _onViewerAvailable(ThermionViewer viewer) async {
    _viewer = viewer;
    _renderer = SceneRenderer(viewer);
    await _renderer!.sync(
      _sceneController.bricks,
      _sceneController.selectedInstanceId,
    );
  }

  Future<void> _handleTapDown(TapDownDetails details) async {
    _viewportFocusNode.requestFocus();
    final viewer = _viewer;
    final renderer = _renderer;
    if (viewer == null || renderer == null) return;
    final local = details.localPosition;
    await viewer.view.pick(local.dx.round(), local.dy.round(), (result) {
      _sceneController.select(renderer.instanceIdForEntity(result.entity));
    });
  }

  // Keyboard shortcuts for desktop/web: arrows nudge, R rotates, Delete/
  // Backspace removes — the same actions the on-screen toolbar exposes,
  // just via another input path. Only handled while the viewport itself
  // (not the search field or anything else) holds focus, and only when a
  // brick is selected, so this never steals keys from the dock's search box.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (!_sceneController.hasSelection) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _sceneController.moveSelectedBy(Vector3(0, 0, -kBrickMoveStep));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _sceneController.moveSelectedBy(Vector3(0, 0, kBrickMoveStep));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _sceneController.moveSelectedBy(Vector3(-kBrickMoveStep, 0, 0));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _sceneController.moveSelectedBy(Vector3(kBrickMoveStep, 0, 0));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyR:
        _sceneController.rotateSelectedBy90();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.delete:
      case LogicalKeyboardKey.backspace:
        _sceneController.deleteSelected();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _onBrickSelected(BrickDefinition brick) {
    _sceneController.place(brick);
    // Only true when this came from the modal pull-up tray (phone layout);
    // the permanent iPad side panel never pushes a route, so this is a
    // no-op there. Closing the tray makes the newly placed brick visible
    // immediately instead of leaving it hidden behind the dock.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openBrickDockSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return BrickDock(
              scrollController: scrollController,
              onBrickSelected: _onBrickSelected,
            );
          },
        );
      },
    );
  }

  String _statusText() {
    final count = _sceneController.bricks.length;
    if (count == 0) return 'Tap Bricks to add one to the scene';
    return '$count brick${count == 1 ? '' : 's'} placed — tap one to select it';
  }

  Widget _buildBottomBar({required bool showBrowseButton}) {
    return AnimatedBuilder(
      animation: _sceneController,
      builder: (context, _) {
        if (_sceneController.hasSelection) {
          return SelectionToolbar(controller: _sceneController);
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text(_statusText())),
                if (showBrowseButton) ...[
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: _openBrickDockSheet,
                    icon: const Icon(Icons.widgets_outlined),
                    label: const Text('Bricks'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewport({required bool showBrowseButton}) {
    return Focus(
      focusNode: _viewportFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTapDown: _handleTapDown,
              child: ViewerWidget(
                initialCameraPosition: Vector3(3, 3.5, 6),
                manipulatorType: ManipulatorType.ORBIT,
                background: Colors.black,
                onViewerAvailable: _onViewerAvailable,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildBottomBar(showBrowseButton: showBrowseButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Brick Playground')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideLayout = constraints.maxWidth >= _wideLayoutBreakpoint;
          if (!isWideLayout) {
            return _buildViewport(showBrowseButton: true);
          }
          return Row(
            children: [
              Expanded(child: _buildViewport(showBrowseButton: false)),
              Container(
                width: 340,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: BrickDock(onBrickSelected: _onBrickSelected),
              ),
            ],
          );
        },
      ),
    );
  }
}
