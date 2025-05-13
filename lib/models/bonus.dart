import '/imports.dart';

class Bonus {
  String? id;
  String? type;
  bool? isUsed;
  String? ownerId;
  String? qrCode;
  Timestamp? createdAt;
  Timestamp? expiresAt;

  Bonus({
    this.id,
    this.type,
    this.isUsed,
    this.ownerId,
    this.qrCode,
    this.createdAt,
    this.expiresAt,
  });

  Bonus.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
    isUsed = json['isUsed'];
    ownerId = json['ownerId'];
    qrCode = json['qrCode'];
    createdAt = json['createdAt'];
    expiresAt = json['expiresAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'isUsed': isUsed,
      'ownerId': ownerId,
      'qrCode': qrCode,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
    };
  }
}