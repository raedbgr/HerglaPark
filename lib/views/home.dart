import '/imports.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BitmapDescriptor? _chestIcon;
  final Set<Polygon> parkBoundary = {};
  int chestSize = 5;
  double? currentZoom;
  double? initialZoom;

  // Firestore reference
  final CollectionReference chestsRef = FirebaseFirestore.instance.collection('chests');

  // Markers for chests
  final Set<Marker> markers = {};

  // Visible chests (within proximity)
  final RxSet<String> visibleChestIds = RxSet<String>();

  Future<void> _loadChestIcon() async {
    _chestIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(
        devicePixelRatio: 2.0,
        size: Size(
          chestSize.toDouble(),
          chestSize.toDouble(),
        ),
      ),
      'assets/images/chest.png',
    );
  }

  void _setupFirestoreListener() {
    chestsRef.snapshots().listen((snapshot) {
      _updateChestMarkers(snapshot);
    });
  }

  void _updateChestMarkers(QuerySnapshot snapshot) {
    if (mounted) {
      setState(() {
        markers.clear();

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final location = data['location'] as Map<String, dynamic>;
          final lat = location['lat'];
          final lng = location['lng'];
          final chestLocation = LatLng(lat, lng);

          // Check if chest is within proximity
          final bool isInProximity = homeCtrl.isChestInProximity(chestLocation);

          // Update visible chests set
          if (isInProximity) {
            visibleChestIds.add(doc.id);
          } else {
            visibleChestIds.remove(doc.id);
          }

          // Only add marker if chest is within proximity
          if (isInProximity) {
            markers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: chestLocation,
                icon: _chestIcon!, // Safe to use after initialization
                onTap: () {
                  // Randomly select challenge
                  final challenges = ['quiz', 'whack_a_mole'];
                  final selectedChallenge = challenges[Random().nextInt(challenges.length)];
                  _showChallengeBottomSheet(context, doc.id, selectedChallenge);
                },
              ),
            );
          }
        }
      });
    }
  }

  void _showChallengeBottomSheet(BuildContext context, String chestId, String challengeType) {
    // Check if chest is on cooldown
    FirebaseFirestore.instance.collection('chests').doc(chestId).get().then((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // Check if chest is on cooldown
        if (data.containsKey('cooldownUntil')) {
          final cooldownUntil = data['cooldownUntil'] as Timestamp;
          final cooldownEnd = cooldownUntil.toDate().add(Duration(minutes: 5));

          if (DateTime.now().isBefore(cooldownEnd)) {
            final remainingMinutes = cooldownEnd.difference(DateTime.now()).inMinutes + 1;
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Chest Locked'),
                content: Text('This chest is still locked. You can try again in $remainingMinutes minutes.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
            return;
          }
        }

        // Show the selected challenge
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            if (challengeType == 'quiz') {
              return QuizScreen(
                chestId: chestId,
                onSuccess: () {},
                onFailure: () {},
              );
            } else {
              return WhackAMole(
                chestId: chestId,
                onSuccess: () {},
                onFailure: () {},
              );
            }
          },
        );
      }
    });
  }

  void _setupBoudaries() {
    // Define the park boundary polygon
    parkBoundary.add(
      Polygon(
        polygonId: PolygonId('park_boundary'),
        points: parkPolygonCoords.map((latLng) => LatLng(latLng.latitude, latLng.longitude)).toList(),
        strokeWidth: 2,
        strokeColor: themeCtrl.primaryColor,
        fillColor: Colors.transparent,
      ),
    );
  }

  Future<void> _initialize() async {
    await _loadChestIcon();
    _setupFirestoreListener();
    _setupBoudaries();
  }

  @override
  void initState() {
    super.initState();
    _initialize();

    // Listen for location updates to refresh chest visibility
    ever(homeCtrl.currentPosition, (_) {
      chestsRef.get().then((snapshot) => _updateChestMarkers(snapshot));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onScaleStart: (ScaleStartDetails details) {
              initialZoom = currentZoom;
            },
            onScaleUpdate: (ScaleUpdateDetails details) {
              if (initialZoom != null && currentZoom != null && homeCtrl.mapController != null) {
                double newZoom = initialZoom! + (details.scale - 1) * 2.0;
                homeCtrl.mapController.moveCamera(CameraUpdate.zoomTo(newZoom));
              }
            },
            child: GoogleMap(
              onMapCreated: homeCtrl.onMapCreated,
              initialCameraPosition: homeCtrl.initialPosition,
              polygons: parkBoundary,
              markers: markers,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              buildingsEnabled: false,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              scrollGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              zoomGesturesEnabled: false,
              onCameraMove: (CameraPosition position) {
                currentZoom = position.zoom;
              },
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: FloatingActionButton(
              heroTag: "leaderboardBtn",
              shape: CircleBorder(),
              backgroundColor: themeCtrl.backgroundColor,
              onPressed: () {
                Get.toNamed('/leaderboard');
              },
              child: Icon(
                Icons.emoji_events,
                size: 25,
                color: themeCtrl.primaryColor,
              ),
            ),
          ),
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
          Positioned(
            top: 80,
            left: 16,
            child: Obx(
                  () => Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: themeCtrl.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Image.asset('assets/images/chest.png', height: 24),
                    SizedBox(width: 8),
                    Text(
                      '${visibleChestIds.length} nearby',
                      style: TextStyle(
                        color: themeCtrl.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void generateRandomChests(int count) async {
    if (_chestIcon == null) return;

    for (int i = 0; i < count; i++) {
      final randomLocation = generateRandomPointInPolygon(parkPolygonCoords);
      final randomBonusType = getRandomBonusType();

      final uuid = Uuid().v4();

      await chestsRef.doc(uuid).set({
        'id': uuid,
        "location": Location(lat: randomLocation.latitude, lng: randomLocation.longitude).toJson(),
        'bonusType': randomBonusType,
        'spawnedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(days: 7))),
      });

      print("## Chest $uuid generated and saved successfully!");

      if (homeCtrl.isChestInProximity(randomLocation) && mounted) {
        setState(() {
          markers.add(
            Marker(
              markerId: MarkerId(uuid),
              position: randomLocation,
              icon: _chestIcon!,
              onTap: () {
                final challenges = ['quiz', 'whack_a_mole'];
                final selectedChallenge = challenges[Random().nextInt(challenges.length)];
                _showChallengeBottomSheet(context, uuid, selectedChallenge);
              },
            ),
          );
          visibleChestIds.add(uuid);
        });
      }
    }
  }

  void setChestSize(int size) {
    if (mounted) {
      setState(() {
        chestSize = size;
      });
    }
    _loadChestIcon().then((_) {
      chestsRef.get().then((snapshot) => _updateChestMarkers(snapshot));
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
  int j = polygon.length - 1;

  for (int i = 0; i < polygon.length; i++) {
    if (((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
        (point.longitude <
            (polygon[j].longitude - polygon[i].longitude) *
                (point.latitude - polygon[i].latitude) /
                (polygon[j].latitude - polygon[i].latitude) +
                polygon[i].longitude)) {
      c = !c;
    }
    j = i;
  }

  return c;
}

// Function to generate a random bonus type
String getRandomBonusType() {
  final List<String> bonusTypes = ["vr", "karting", "shooting"];
  final random = Random();
  return bonusTypes[random.nextInt(bonusTypes.length)];
}