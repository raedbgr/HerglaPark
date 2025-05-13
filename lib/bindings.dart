import 'imports.dart';

class MyBindings extends Bindings {
  @override
  void dependencies() {
    // Created at start
    Get.put(AuthController());
    Get.put(HomeController());

    // Created when needed
    // Get.lazyPut<HomeController>(() => HomeController());
  }
}