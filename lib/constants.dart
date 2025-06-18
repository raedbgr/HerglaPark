import 'imports.dart';

AuthController get authCtrl => Get.find<AuthController>();
HomeController get homeCtrl => Get.find<HomeController>();
ThemeController get themeCtrl => Get.find<ThemeController>();
// WamController get wamCtrl => Get.find<WamController>();

final List<LatLng> parkPolygonCoords = [
  LatLng(36.02558924696962, 10.489096735543416),
  LatLng(36.026465618407755, 10.491784309023553),
  LatLng(36.02419657725403, 10.493120049136435),
  LatLng(36.02388853793844, 10.492401217101595),
  LatLng(36.02401001837165, 10.491945241561053),
  LatLng(36.024036049868684, 10.49122104511431),
  LatLng(36.02370197833702, 10.490169619162002),
  LatLng(36.0255458619814, 10.4890752778647),
];
