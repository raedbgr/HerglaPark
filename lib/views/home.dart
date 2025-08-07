import '/imports.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Replace single chest icon with a map of chest icons
  final Map<String, BitmapDescriptor> _chestIcons = {};
  final Set<Polygon> parkBoundary = {};
  int chestSize = 5;
  double? currentZoom;
  double? initialZoom;
  bool _isConnectivityAlertShown = false;
  bool _isOutsideParkAlertShown = false; // Flag to prevent multiple outside park alerts

  // Firestore reference
  final CollectionReference chestsRef = FirebaseFirestore.instance.collection('chests');

  // Markers for chests
  final Set<Marker> markers = {};

  // Visible chests (within proximity)
  final RxSet<String> visibleChestIds = RxSet<String>();

  // Load all chest icons
  Future<void> _loadChestIcons() async {
    _chestIcons.clear();
    final BitmapDescriptor chestIcon = await BitmapDescriptor.asset(
      height: 75,
      width: 75,
      ImageConfiguration(devicePixelRatio: 2.0, size: Size(chestSize.toDouble(), chestSize.toDouble())),
      'assets/images/chest.png',
    );

    // Use same icon for all chests
    _chestIcons['default'] = chestIcon;
  }

  void _setupFirestoreListener() {
    chestsRef.snapshots().listen(
          (snapshot) {
        _updateChestMarkers(snapshot);
        _isConnectivityAlertShown = false; // Reset alert flag on successful data fetch
      },
      onError: (error) {
        if (mounted && !_isConnectivityAlertShown) {
          _isConnectivityAlertShown = true;
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => AlertDialog(
              title: Text('Connection Issue'),
              content: Text(
                'Your internet connection is unstable. It may take a bit to load chests and your location.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  void _updateChestMarkers(QuerySnapshot snapshot) {
    if (mounted) {
      setState(() {
        markers.clear();
        visibleChestIds.clear();

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
            // Use the default chest icon
            final icon = _chestIcons['default']!;

            markers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: chestLocation,
                icon: icon,
                consumeTapEvents: true, // Prevent map from centering on tap
                onTap: () {
                  _handleChestTap(context, doc.id);
                },
              ),
            );
          }
        }
      });
    }
  }

  void _handleChestTap(BuildContext context, String chestId) {
    FirebaseFirestore.instance.collection('chests').doc(chestId).get().then((doc) {
      if (!mounted || !doc.exists) return;

      final data = doc.data()!;
      if (data.containsKey('cooldownUntil')) {
        final cooldownUntil = data['cooldownUntil'] as Timestamp;
        final cooldownEnd = cooldownUntil.toDate().add(Duration(minutes: 5));

        if (DateTime.now().isBefore(cooldownEnd)) {
          final remainingMinutes = cooldownEnd.difference(DateTime.now()).inMinutes + 1;
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 15,
                  children: [
                    Image.asset('assets/images/alerts/locked.png', height: 120,),
                    Text(
                      'Coffre Verrouillé',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'myFont',
                          fontSize: 24,
                          fontStyle: FontStyle.italic
                      ),
                    ),
                    Text(
                      'Ce coffre est encore verrouillé. Réessayez dans $remainingMinutes minutes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic
                      ),
                    ),
                    SizedBox(),
                    InkWell(
                      onTap: () {
                        Get.back();
                      },
                      splashColor: Colors.black.withValues(alpha: 0.3),
                      child: Ink(
                        padding: EdgeInsets.symmetric(vertical: 3, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          'OK',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: themeCtrl.textColor,
                              fontSize: 16
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            )
          );
          return;
        }
      }

      // Show spinning wheel
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => GameWheelDialog(chestId: chestId),
      );
    });
  }

  void _checkUserLocation() {
    if (homeCtrl.currentPosition.value != null && mounted && !_isOutsideParkAlertShown) {
      final userLocation = LatLng(
        homeCtrl.currentPosition.value!.latitude,
        homeCtrl.currentPosition.value!.longitude,
      );
      if (!_isPointInPolygon(userLocation, parkPolygonCoords)) {
        _isOutsideParkAlertShown = true;
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 15,
                children: [
                  Image.asset('assets/images/alerts/warning.png', height: 120,),
                  Text(
                    'Hors des Limites du Parc',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'myFont',
                        fontSize: 24,
                        fontStyle: FontStyle.italic
                    ),
                  ),
                  Text(
                    'Vous êtes actuellement hors des limites du parc. Les coffres ne peuvent être trouvés qu’à l’intérieur du parc.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic
                    ),
                  ),
                  SizedBox(),
                  InkWell(
                    onTap:  () {
                      _isOutsideParkAlertShown = false;
                      Get.back();
                    },
                    splashColor: Colors.black.withValues(alpha: 0.3),
                    child: Ink(
                      padding: EdgeInsets.symmetric(vertical: 3, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        'OK',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: themeCtrl.textColor,
                            fontSize: 16
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      } else {
        _isOutsideParkAlertShown = false; // Reset flag if user is inside the park
      }
    }
  }

  void _setupBoundaries() {
    parkBoundary.add(
      Polygon(
        polygonId: PolygonId('park_boundary'),
        points: parkPolygonCoords.map((latLng) => LatLng(latLng.latitude, latLng.longitude)).toList(),
        strokeWidth: 0,
        strokeColor: Colors.transparent,
        fillColor: Colors.transparent,
      ),
    );
  }

  Future<void> _initialize() async {
    await _loadChestIcons();
    _setupFirestoreListener();
    _setupBoundaries();
  }

  @override
  void initState() {
    super.initState();
    _initialize();

    ever(homeCtrl.currentPosition, (_) {
      chestsRef.get().then((snapshot) => _updateChestMarkers(snapshot));
      _checkUserLocation(); // Check user location on position update
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
              if (initialZoom != null && currentZoom != null) {
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
              style: homeCtrl.mapStyle.value,
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
          // Positioned(
          //   bottom: 16,
          //   right: 16,
          //   child: FloatingActionButton(
          //     heroTag: "addChestBtn",
          //     onPressed: _chestIcons.isNotEmpty ? () => generateRandomChests(5) : null,
          //     child: Icon(Icons.add),
          //   ),
          // ),
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
                      '${visibleChestIds.length} proche',
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
    if (_chestIcons.isEmpty) return;

    for (int i = 0; i < count; i++) {
      final randomLocation = generateRandomPointInPolygon(parkPolygonCoords);
      final uuid = Uuid().v4();

      await chestsRef.doc(uuid).set({
        'id': uuid,
        'location': Location(lat: randomLocation.latitude, lng: randomLocation.longitude).toJson(),
        'spawnedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(hours: 24))),
      });

      print("## Chest $uuid generated and saved successfully!");

      if (homeCtrl.isChestInProximity(randomLocation) && mounted) {
        setState(() {
          markers.add(
            Marker(
              markerId: MarkerId(uuid),
              position: randomLocation,
              icon: _chestIcons['default']!,
              consumeTapEvents: true,
              onTap: () {
                _handleChestTap(context, uuid);
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
    _loadChestIcons().then((_) {
      chestsRef.get().then((snapshot) => _updateChestMarkers(snapshot));
    });
  }
}

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
