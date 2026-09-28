import 'dart:async';

import 'package:flutter/material.dart';
import 'package:thermion_flutter/thermion_flutter.dart';

/// Phase 1 validation spike: proves out the Thermion/Filament renderer
/// embedded in Flutter before committing to it for the real app. Renders a
/// single procedural cube (no brick assets yet) and tests the two riskiest
/// unknowns: orbit-gesture camera control and tap-to-pick raycasting.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Renderer Spike (Thermion/Filament)')),
      body: Stack(
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
                padding: const EdgeInsets.all(12),
                child: Text(_status, textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
