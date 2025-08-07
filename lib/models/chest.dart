import '/imports.dart';

class Chest {
  String id;
  Location location;
  Timestamp spawnedAt;
  Timestamp expiresAt;

  Chest({
    required this.id,
    required this.location,
    required this.spawnedAt,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location.toJson(),
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
    return {'lat': lat, 'lng': lng};
  }
}
