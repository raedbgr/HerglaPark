import 'imports.dart';

class MyBindings extends Bindings {
  @override
  void dependencies() {
    // Created at start
    Get.put(AuthController());

    // Created when needed
    // Get.lazyPut<MapController>(() => MapController());
  }
}