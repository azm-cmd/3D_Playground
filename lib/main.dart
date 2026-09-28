import 'dart:async';

import 'package:flutter/material.dart';
import 'package:thermion_flutter/thermion_flutter.dart';

import 'catalog/brick_definition.dart';
import 'catalog/brick_dock.dart';

/// Below this width the brick dock lives in a pull-up tray; at or above it,
/// it docks permanently beside the viewport (roughly phone vs. iPad width).
const double _wideLayoutBreakpoint = 700;

/// Phase 1 validation spike: proves out the Thermion/Filament renderer
/// embedded in Flutter before committing to it for the real app. Renders a
/// single procedural cube (no brick assets yet) and tests the two riskiest
/// unknowns: orbit-gesture camera control and tap-to-pick raycasting.
///
/// Phase 2 adds the data-driven brick catalog and its browse/search dock
/// (see lib/catalog/) alongside this viewport. The dock is intentionally
/// not wired to the 3D scene yet — selecting a brick here does not place,
/// select, or snap anything in the viewport. That comes in a later phase.
void main() {
  runApp(const BrickPlaygroundApp());
}

class BrickPlaygroundApp extends StatelessWidget {
  const BrickPlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brick Playground — Renderer Spike',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const RendererSpikeScreen(),
    );
  }
}

class RendererSpikeScreen extends StatefulWidget {
  const RendererSpikeScreen({super.key});

  @override
  State<RendererSpikeScreen> createState() => _RendererSpikeScreenState();
}

class _RendererSpikeScreenState extends State<RendererSpikeScreen> {
  static const _defaultColor = (r: 0.25, g: 0.45, b: 0.95, a: 1.0);
  static const _selectedColor = (r: 0.95, g: 0.55, b: 0.15, a: 1.0);

  ThermionViewer? _viewer;
  ThermionAsset? _cubeAsset;
  UbershaderMaterialInstance? _cubeMaterial;
  bool _selected = false;
  String _status = 'Initializing renderer…';

  Future<void> _onViewerAvailable(ThermionViewer viewer) async {
    _viewer = viewer;
    final material = UbershaderMaterialInstance(
      await viewer.app.createUbershaderMaterialInstance(),
    );
    await material.setBaseColorFactor(
      _defaultColor.r,
      _defaultColor.g,
      _defaultColor.b,
      _defaultColor.a,
    );
    final asset = await viewer.createGeometry(
      CubeGeometry.cube(),
      materialInstances: [material.materialInstance],
    );
    if (!mounted) return;
    setState(() {
      _cubeAsset = asset;
      _cubeMaterial = material;
      _status = 'Cube rendered — drag to orbit, tap the cube to pick it';
    });
  }

  Future<void> _handleTapDown(TapDownDetails details) async {
    final viewer = _viewer;
    if (viewer == null) return;
    final local = details.localPosition;
    await viewer.view.pick(local.dx.round(), local.dy.round(), _onPickResult);
  }

  void _onPickResult(PickResult result) {
    final cube = _cubeAsset;
    final material = _cubeMaterial;
    if (cube == null || material == null || !mounted) return;

    if (result.entity == cube.entity) {
      final next = !_selected;
      final color = next ? _selectedColor : _defaultColor;
      unawaited(
        material.setBaseColorFactor(color.r, color.g, color.b, color.a),
      );
      setState(() {
        _selected = next;
        _status = next ? 'Picked: cube selected' : 'Picked: cube deselected';
      });
    } else {
      setState(() => _status = 'Pick missed the cube (background hit)');
    }
  }

  void _onBrickSelected(BrickDefinition brick) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${brick.name} selected — placing bricks arrives in a later phase.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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

  Widget _buildViewport({required bool showBrowseButton}) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTapDown: _handleTapDown,
            child: ViewerWidget(
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
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Expanded(child: Text(_status)),
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
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Renderer Spike (Thermion/Filament)')),
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
