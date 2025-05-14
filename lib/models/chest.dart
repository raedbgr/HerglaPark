import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart'; // For generating UUIDs
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants.dart'; // For Firestore integration

class Chest {
  String id;
  Location location;
  String bonusType;
  Timestamp spawnedAt;
  Timestamp expiresAt;

  Chest({
    required this.id,
    required this.location,
    required this.bonusType,
    required this.spawnedAt,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location.toJson(),
      'bonusType': bonusType,
      'spawnedAt': spawnedAt,
      'expiresAt': expiresAt,
    };
  }
}

class Location {
  double lat;
  double lng;

  Location({required this.lat, required this.lng});

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}


