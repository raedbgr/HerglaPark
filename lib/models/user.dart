import '/imports.dart';

class UserModel {
  String? id;
  String? username;
  String? avatar;
  String? email;
  int? chestsOpened;
  Timestamp? createdAt;

  UserModel({
    this.id,
    this.username,
    this.avatar,
    this.email,
    this.chestsOpened,
    this.createdAt,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    email = json['email'];
    avatar = json['avatar'];
    chestsOpened = json['chestsOpened'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar': avatar,
      'chestsOpened': chestsOpened,
      'createdAt': createdAt,
    };
  }
}