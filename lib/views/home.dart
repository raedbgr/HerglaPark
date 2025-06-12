import '/imports.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BitmapDescriptor? _chestIcon;
  final Set<Polygon> parkBoundary = {};
  int chestSize = 15;

  // Firestore reference
  final CollectionReference chestsRef = FirebaseFirestore.instance.collection('chests');

  // Markers for chests
  final Set<Marker> markers = {};

  // Map Camera Position


  Future<void> _loadChestIcon() async {
    _chestIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(
        devicePixelRatio: 2.0,
        size: Size(chestSize.toDouble(), chestSize.toDouble()), // Use chestSize here
      ),
      'assets/images/chest.png',
    );
  }

  void _setupFirestoreListener() {
    chestsRef.snapshots().listen((snapshot) {
      setState(() {
        markers.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final location = data['location'] as Map<String, dynamic>;
          final lat = location['lat'];
          final lng = location['lng'];
          markers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(lat, lng),
              icon: _chestIcon!, // Safe to use after initialization
              onTap: () {
                // Show quiz challenge when marker is tapped
                showQuizBottomSheet(context, doc.id);
              },
            ),
          );
        }
      });
    });
  }

  void _setupBoudaries() {
    // Define the park boundary polygon
    parkBoundary.add(
      Polygon(
        polygonId: PolygonId('park_boundary'),
        points: parkPolygonCoords.map((latLng) => LatLng(latLng.latitude, latLng.longitude)).toList(),
        strokeWidth: 2, // Thickness of the border line
        strokeColor: themeCtrl.primaryColor, // Green color for the boundary
        fillColor: Colors.transparent, // Transparent fill (only outline)
      ),
    );
  }

  Future<void> _initialize() async {
    await _loadChestIcon(); // Wait for the icon to load
    _setupFirestoreListener(); // Then set up the listener
    _setupBoudaries();
  }

  @override
  void initState() {
    super.initState();
    // Listen for real-time updates from Firestore
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: homeCtrl.onMapCreated,
              initialCameraPosition: homeCtrl.initialPosition,
            polygons: parkBoundary, // Add the park boundary here
            markers: markers,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
          ),
             // Leaderboard Button (Top-Left)
            Positioned(
              top: 16,
              left: 16,
              child: FloatingActionButton(
                heroTag: "leaderboardBtn",
                shape: CircleBorder(),
                backgroundColor: themeCtrl.backgroundColor,
                onPressed: () {
                  // leaderboard logic
                  Get.toNamed('/leaderboard');
                },
                child: Icon(
                  Icons.emoji_events,
                  size: 25,
                  color: themeCtrl.primaryColor,
                ),
              ),
            ),

            // Profile Button (Top-Right)
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: "profileBtn",
                shape: CircleBorder(),
                backgroundColor: themeCtrl.backgroundColor,
                onPressed: () {
                  Get.toNamed('/profile');
                },
                child: Icon(
                  Icons.person_rounded,
                  size: 25,
                  color: themeCtrl.primaryColor,
                ),
              ),
            ),
         
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: "addChestBtn",
              onPressed: _chestIcon != null ? () => generateRandomChests(5) : null,
              child: Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  void generateRandomChests(int count) async {
    if (_chestIcon == null) return; // Wait for the icon to load

    for (int i = 0; i < count; i++) {
      final randomLocation = generateRandomPointInPolygon(parkPolygonCoords);
      final randomBonusType = getRandomBonusType();

      // Generate a unique ID
      final uuid = Uuid().v4();

      // Create the chest document in Firestore
      await chestsRef.doc(uuid).set({
        'id': uuid,
        "location": Location(
            lat: randomLocation.latitude,
            lng: randomLocation.longitude)
            .toJson(),
        'bonusType': randomBonusType,
        'spawnedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(days: 7))),
      });

      print("## Chest $uuid generated and saved successfully!");

      // Add the marker to the map
      setState(() {
        markers.add(
          Marker(
            markerId: MarkerId(uuid),
            position: randomLocation,
            icon: _chestIcon!, // Use the pre-loaded icon ✅
            onTap: () {
              // Show quiz challenge when marker is tapped
              showQuizBottomSheet(context, uuid);
            },
          ),
        );
      });
    }
  }

  // Method to change chest icon size
  void setChestSize(int size) {
    setState(() {
      chestSize = size;
    });
    // Reload the icon with new size
    _loadChestIcon().then((_) {
      // Refresh all markers to use the new icon
      _setupFirestoreListener();
    });
  }
}

// Function to generate a random point inside a polygon
LatLng generateRandomPointInPolygon(List<LatLng> polygon) {
  final random = Random();
  double minLat = polygon.map((p) => p.latitude).reduce(min);
  double maxLat = polygon.map((p) => p.latitude).reduce(max);
  double minLng = polygon.map((p) => p.longitude).reduce(min);
  double maxLng = polygon.map((p) => p.longitude).reduce(max);

  while (true) {
    double randomLat = minLat + random.nextDouble() * (maxLat - minLat);
    double randomLng = minLng + random.nextDouble() * (maxLng - minLng);
    final point = LatLng(randomLat, randomLng);

    if (_isPointInPolygon(point, polygon)) {
      return point;
    }
  }
}

// Helper function to check if a point is inside a polygon
bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
  bool c = false;
  int j = polygon.length - 1; // Initialize j outside the loop

  for (int i = 0; i < polygon.length; i++) {
    if (((polygon[i].latitude > point.latitude) !=
        (polygon[j].latitude > point.latitude)) &&
        (point.longitude <
            (polygon[j].longitude - polygon[i].longitude) *
                (point.latitude - polygon[i].latitude) /
                (polygon[j].latitude - polygon[i].latitude) +
                polygon[i].longitude)) {
      c = !c; // Toggle the flag
    }
    j = i; // Update j to the current index
  }

  return c;
}

// Function to generate a random bonus type
String getRandomBonusType() {
  final List<String> bonusTypes = ["vr", "karting", "shooting"];
  final random = Random();
  return bonusTypes[random.nextInt(bonusTypes.length)];
}
