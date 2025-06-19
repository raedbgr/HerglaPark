import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:permission_handler/permission_handler.dart';

class TreasureHunt extends StatefulWidget {
  const TreasureHunt({super.key});

  @override
  State<TreasureHunt> createState() => _TreasureHuntState();
}

class _TreasureHuntState extends State<TreasureHunt> {
  late ArCoreController _arCoreController;
  bool _cameraGranted = false;
  bool _permissionChecked = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _cameraGranted = status == PermissionStatus.granted;
      _permissionChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // While we’re checking/requesting permission
    if (!_permissionChecked) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If permission was denied, show prompt
    if (!_cameraGranted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treasure Hunt')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Camera access is required to play.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPermission,
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    // Permission granted → show AR view
    return Scaffold(
      body: ArCoreView(
        onArCoreViewCreated: _onArCoreViewCreated,
        enableTapRecognizer: true,  // if you want to add tap handlers later
      ),
    );
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    _arCoreController = controller;

    // place the chest 1m in front
    final chestNode = ArCoreReferenceNode(
      objectUrl: 'assets/3d_models/treasure_chest_animated.glb',
      scale: vector.Vector3(0.5, 0.5, 0.5),
      position: vector.Vector3(0, 0, -1),
    );

    _arCoreController.addArCoreNode(chestNode);
  }

  @override
  void dispose() {
    _arCoreController.dispose();
    super.dispose();
  }
}
