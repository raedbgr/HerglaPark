

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';
import '../models/chest.dart';

class ChestMapScreen extends StatefulWidget {
  @override
  _ChestMapScreenState createState() => _ChestMapScreenState();
}

class _ChestMapScreenState extends State<ChestMapScreen> {
  BitmapDescriptor? _chestIcon; // Store the icon here
  late GoogleMapController mapController;

  // Firestore reference
  final CollectionReference chestsRef = FirebaseFirestore.instance.collection('chests');

  // Markers for chests
  final Set<Marker> markers = {};

  // Map Camera Position
  final CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(36.02558924696962, 10.489096735543416),
    zoom: 15,
  );
  Future<void> _loadChestIcon() async {
    _chestIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.0),
      'assets/images/chest.png',
    );
  }
  @override
  void initState() {
    super.initState();
    // Listen for real-time updates from Firestore
    _loadChestIcon(); // Load the icon once when the screen initializes

    chestsRef.snapshots().listen((snapshot) {
      setState(() async {
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
              icon: _chestIcon!, // Use the pre-loaded icon ✅

            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Park Chests'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
            },
            initialCameraPosition: initialCameraPosition,
            markers: markers,
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                generateRandomChests(5);
              },
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

      print("## Chest ${uuid} generated and saved successfully!");

      // Add the marker to the map
      setState(() {
        markers.add(
          Marker(
            markerId: MarkerId(uuid),
            position: randomLocation,
            icon: _chestIcon!, // Use the pre-loaded icon ✅
          ),
        );
      });
    }
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
  final List<String> bonusTypes = ["vr", "carting", "shooting"];
  final random = Random();
  return bonusTypes[random.nextInt(bonusTypes.length)];
}
