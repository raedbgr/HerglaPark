import 'imports.dart';

AuthController get authCtrl => Get.find<AuthController>();
HomeController get homeCtrl => Get.find<HomeController>();
ThemeController get themeCtrl => Get.find<ThemeController>();

final List<LatLng> parkPolygonCoords = [
  LatLng(36.0256027822365, 10.489141022478105),
  LatLng(36.02614451424541, 10.490908117303828),
  LatLng(36.025210669137984, 10.491392951982972),
  LatLng(36.0247514815727, 10.490442420835707),
  LatLng(36.02444191540107, 10.490557250098494),
  LatLng(36.02449866928829, 10.490888979089485),
  LatLng(36.02423553728472, 10.491073981796001),
  LatLng(36.02380730096865, 10.490187244685464),
  LatLng(36.025576985378315, 10.48913464307943),
];
