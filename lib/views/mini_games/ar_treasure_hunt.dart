import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class TreasureHunt extends StatefulWidget {
  const TreasureHunt({super.key});
  @override
  State<TreasureHunt> createState() => _TreasureHuntState();
}

class _TreasureHuntState extends State<TreasureHunt> {
  late ArCoreController arCoreController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArCoreView(onArCoreViewCreated: _onArCoreViewCreated),
    );
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;

    final node = ArCoreReferenceNode(
      objectUrl: "assets/3d_models/treasure_chest_animated.glb",
      scale: vector.Vector3(0.5, 0.5, 0.5),
      position: vector.Vector3(0, 0, -1),
    );
    arCoreController.addArCoreNode(node);
  }

  @override
  void dispose() {
    arCoreController.dispose();
    super.dispose();
  }
}
