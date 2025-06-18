import 'imports.dart';

class MyBindings extends Bindings {
  @override
  void dependencies() {
    // Created at start
    Get.put(AuthController());
    Get.put(HomeController());
    Get.put(ThemeController());
    // created at demand
    Get.lazyPut<WamController>(() => WamController());
  }
}
