import '/imports.dart';

class Chest {
  String? id;
  Map? location;
  bool? isOpened;
  String? bonusType;
  Timestamp? spawnedAt;
  Timestamp? expiresAt;

  Chest({
    this.id,
    this.location,
    this.isOpened,
    this.bonusType,
    this.spawnedAt,
    this.expiresAt,
  });

  Chest.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    location = json['location'];
    isOpened = json['isOpened'];
    bonusType = json['bonusType'];
    spawnedAt = json['spawnedAt'];
    expiresAt = json['expiresAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'isOpened': isOpened,
      'bonusType': bonusType,
      'spawnedAt': spawnedAt,
      'expiresAt': expiresAt,
    };
  }
}