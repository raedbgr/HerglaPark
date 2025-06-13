import '/imports.dart';

class HomeController extends GetxController {
  late GoogleMapController mapController;

  // Observable variables for user's current location
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxBool isLocationServiceEnabled = false.obs;
  final RxDouble proximityThreshold = 12.0.obs;

  // Remove these variables as we'll use the built-in location indicator
  // final Rx<Marker?> userMarker = Rx<Marker?>(null);
  // BitmapDescriptor? userLocationIcon;

  final CameraPosition initialPosition = CameraPosition(
    target: const LatLng(36.0251, 10.4901), // Adjust as needed
    zoom: 19.3,
  );

  @override
  void onInit() {
    super.onInit();
    _initLocationTracking();
    // Remove this line as we don't need to load a custom icon anymore
    // _loadUserLocationIcon();
  }

  @override
  void onClose() {
    // Cancel any active location subscriptions
    stopLocationUpdates();
    super.onClose();
  }

  // Initialize location tracking
  Future<void> _initLocationTracking() async {
    try {
      // Check if location services are enabled
      isLocationServiceEnabled.value =
          await Geolocator.isLocationServiceEnabled();

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

  // Remove the _loadUserLocationIcon method as we don't need it anymore

  // Start location updates
  void startLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update if user moves 5 meters
      ),
    ).listen((Position position) {
      currentPosition.value = position;
      // Remove this line as we don't need to update a custom marker anymore
      // _updateUserMarker(position);
      animateToUserLocation(position);
    });
  }

  // Stop location updates
  void stopLocationUpdates() {
    // This method would cancel the stream subscription if needed
  }

  // Remove the _updateUserMarker method as we don't need it anymore

  // Animate camera to user location
  void animateToUserLocation(Position position) {
    mapController.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );
  }

  void onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    String style = await rootBundle.loadString('assets/map/map_style.json');
    mapController.setMapStyle(style);

    // If we already have a position, move camera to it
    if (currentPosition.value != null) {
      animateToUserLocation(currentPosition.value!);
    }
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
