import '/imports.dart';

class HomeController extends GetxController {
  late GoogleMapController mapController;
  final CameraPosition initialPosition = CameraPosition(
    target: const LatLng(36.0251, 10.4901), // Adjust as needed
    zoom: 16,
  );

  void onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    String style = await rootBundle.loadString('assets/map_style.json');
    mapController.setMapStyle(style);
  }
}