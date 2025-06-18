import '/imports.dart';
import 'dart:math';
import 'package:flutter/animation.dart';

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
                consumeTapEvents: true, // Prevent map from centering on tap
                onTap: () {
                  _showMiniGameSelectorDialog(context, doc.id);
                },
              ),
            );
          }
        }
      });
    }
  }

  void _showMiniGameSelectorDialog(BuildContext context, String chestId) {
    // Check if chest is on cooldown
    FirebaseFirestore.instance.collection('chests').doc(chestId).get().then((doc) {
      if (doc.exists && mounted) {
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

        // Show mini-game selector dialog
        showDialog(
          context: context,
          barrierDismissible: false, // Non-dismissible
          builder: (context) => MiniGameSelectorDialog(
            onGameSelected: (selectedChallenge) {
              _showChallengeBottomSheet(context, chestId, selectedChallenge);
            },
          ),
        );
      }
    });
  }

  void _showChallengeBottomSheet(BuildContext context, String chestId, String challengeType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        if (challengeType == 'quiz') {
          return QuizScreen(
            chestId: chestId,
            onSuccess: () {
              if (homeCtrl.currentPosition.value != null) {
                homeCtrl.animateToUserLocation(homeCtrl.currentPosition.value!);
              }
            },
            onFailure: () {
              if (homeCtrl.currentPosition.value != null) {
                homeCtrl.animateToUserLocation(homeCtrl.currentPosition.value!);
              }
            },
          );
        } else {
          return WhackAMole(
            chestId: chestId,
            onSuccess: () {
              if (homeCtrl.currentPosition.value != null) {
                homeCtrl.animateToUserLocation(homeCtrl.currentPosition.value!);
              }
            },
            onFailure: () {
              if (homeCtrl.currentPosition.value != null) {
                homeCtrl.animateToUserLocation(homeCtrl.currentPosition.value!);
              }
            },
          );
        }
      },
    );
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
              consumeTapEvents: true, // Prevent map from centering on tap
              onTap: () {
                _showMiniGameSelectorDialog(context, uuid);
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

// Mini-game selector dialog with slot machine animation
class MiniGameSelectorDialog extends StatefulWidget {
  final Function(String) onGameSelected;

  const MiniGameSelectorDialog({super.key, required this.onGameSelected});

  @override
  _MiniGameSelectorDialogState createState() => _MiniGameSelectorDialogState();
}

class _MiniGameSelectorDialogState extends State<MiniGameSelectorDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late ScrollController _scrollController;
  final List<String> games = ['quiz', 'whack_a_mole', 'quiz', 'whack_a_mole']; // Repeated for seamless loop
  String selectedGame = '';
  bool isSpinning = true;

  @override
  void initState() {
    super.initState();

    // Randomly select the target game
    final challenges = ['quiz', 'whack_a_mole'];
    selectedGame = challenges[Random().nextInt(challenges.length)];

    // Initialize scroll controller
    _scrollController = ScrollController();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5), // Total duration of spin
    );

    // Custom curve to simulate slowing down
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Cubic(0.1, 0.9, 0.2, 1.0), // Ease out for deceleration
    );

    // Calculate target position
    final itemHeight = 60.0; // Height of each game name item
    final cycleLength = games.length * itemHeight; // Length of one cycle of games
    final targetIndex = games.indexWhere((game) => game == selectedGame, 1); // Skip first 'quiz'
    final targetOffset = (targetIndex * itemHeight) + (cycleLength * 5) - (itemHeight / 2); // Center after 5 cycles

    // Bind scroll position to animation
    _animation.addListener(() {
      if (_scrollController.hasClients) {
        final progress = _animation.value;
        final scrollPosition = progress * targetOffset;
        _scrollController.jumpTo(scrollPosition % cycleLength); // Loop within cycle
      }
    });

    // Start animation
    _controller.forward().then((_) {
      setState(() {
        isSpinning = false;
      });
      // Ensure final position is exact
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(targetOffset % cycleLength);
      }
      // Delay to show result, then close dialog and trigger callback
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onGameSelected(selectedGame);
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getDisplayName(String game) {
    return game == 'quiz' ? 'Quiz' : 'Whack a Mole';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 300,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Selecting Mini-Game...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                // Slot machine container
                Container(
                  height: 100,
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[100],
                  ),
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.3, 0.7, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: isSpinning ? NeverScrollableScrollPhysics() : ClampingScrollPhysics(),
                      itemCount: games.length * 10, // Repeat for continuous scroll
                      itemBuilder: (context, index) {
                        final game = games[index % games.length];
                        return Container(
                          height: 60,
                          alignment: Alignment.center,
                          child: Text(
                            _getDisplayName(game),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Top and bottom lines
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 180,
                      height: 2,
                      color: Colors.black87,
                    ),
                    SizedBox(height: 56),
                    Container(
                      width: 180,
                      height: 2,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}