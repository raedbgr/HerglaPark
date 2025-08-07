import '/imports.dart';

class HomeController extends GetxController {
  late GoogleMapController mapController;

  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxBool isLocationServiceEnabled = false.obs;
  final RxDouble proximityThreshold = 15.0.obs;

  final CameraPosition initialPosition = CameraPosition(
    target: const LatLng(36.0251, 10.4901), // Default position
    zoom: 19.3,
  );

  StreamSubscription<Position>? _positionStream;
  final RxnString mapStyle = RxnString(null);

  @override
  void onInit() {
    super.onInit();
    loadMapStyle();
    _initLocationTracking();
  }

  @override
  void onClose() {
    stopLocationUpdates();
    mapController.dispose();
    super.onClose();
  }

  Future<void> loadMapStyle() async {
    final now = DateTime.now();
    final hour = now.hour;
    final isNightTime = hour >= 19 || hour < 5;

    final mapStylePath = isNightTime
        ? 'assets/map/night_map.json'
        : 'assets/map/map_style.json';

    final style = await rootBundle.loadString(mapStylePath);
    mapStyle.value = style;
  }

  // Initialize location tracking
  Future<void> _initLocationTracking() async {
    try {
      // Check if location services are enabled
      isLocationServiceEnabled.value = await Geolocator.isLocationServiceEnabled();

      if (!isLocationServiceEnabled.value) {
        Get.snackbar(
          'Location Services Disabled',
          'Please enable location services to use this app.',
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 5),
        );
        return;
      }

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Location Permission Denied',
            'Location permissions are required for this app.',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Location Permissions Denied',
          'Location permissions are permanently denied. Please enable them in app settings.',
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 5),
        );
        return;
      }

      // Start listening to location updates
      startLocationUpdates();
    } catch (e) {
      print('Error initializing location tracking: $e');
    }
  }

  // Start location updates
  void startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // Update if user moves per meter
      ),
    ).listen((Position position) {
      currentPosition.value = position;
      animateToUserLocation(position);
    });
  }

  // Stop location updates
  void stopLocationUpdates() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  // Animate camera to user location
  void animateToUserLocation(Position position) {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 19.3, // Maintain consistent zoom level
        ),
      ),
    );
  }

  // Explicitly re-center map on user
  void recenterOnUser() {
    if (currentPosition.value != null) {
      animateToUserLocation(currentPosition.value!);
    }
  }

  void onMapCreated(GoogleMapController controller) async {
    mapController = controller;

    // Move camera to user location if available
    recenterOnUser();
  }


  // Calculate distance between two points in meters
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  // Check if a chest is within proximity threshold
  bool isChestInProximity(LatLng chestLocation) {
    if (currentPosition.value == null) return false;

    double distance = calculateDistance(
      LatLng(currentPosition.value!.latitude, currentPosition.value!.longitude),
      chestLocation,
    );

    return distance <= proximityThreshold.value;
  }
}