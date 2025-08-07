import '/imports.dart';

class UserModel {
  String? id;
  String? username;
  String? avatar;
  String? email;
  int? chestsOpened;
  int? points;
  Timestamp? createdAt;

  UserModel({
    this.id,
    this.username,
    this.avatar,
    this.email,
    this.chestsOpened,
    this.points,
    this.createdAt,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    email = json['email'];
    avatar = json['avatar'];
    chestsOpened = json['chestsOpened'];
    points = json['points'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar': avatar,
      'chestsOpened': chestsOpened,
      'points': points,
      'createdAt': createdAt,
    };
  }
}

class PointHistory {
  final int pointsGained;
  final Timestamp timestamp;

  PointHistory({
    required this.pointsGained,
    required this.timestamp,
  });

  PointHistory.fromJson(Map<String, dynamic> json)
      : pointsGained = json['pointsGained'],
        timestamp = json['timestamp'];

  Map<String, dynamic> toJson() {
    return {
      'pointsGained': pointsGained,
      'timestamp': timestamp,
    };
  }
}