import 'dart:convert';

import 'package:our_chat/Models/status_model.dart';

class User {
  late String id;
  late String name;
  late String email;
  late String password;
  late String image;
  late bool isOnline;
  late String joinedOn;
  late String lastActive;
  late List<Status> status;
  late String about;
  late String token;

  User(
      {required this.name,
      required this.id,
      required this.email,
      required this.password,
      required this.image,
      required this.isOnline,
      required this.joinedOn,
      required this.lastActive,
      required this.status,
      required this.about,
      required this.token});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    password = json['password'];
    image = json['image'];
    isOnline = json['isOnline'];
    joinedOn = json['joinedOn'];
    lastActive = json['lastActive'];
    status = (json['status'] as List).map((n) => Status.fromJson(n),).toList();
    about = json['about'];
    token = json['token'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic> {};
    data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['password'] = password;
    data['image'] = image;
    data['isOnline'] = isOnline;
    data['joinedOn'] = joinedOn;
    data['lastActive'] = lastActive;
    data['status'] = status;
    data['about'] = about;
    data['token'] = token;
    return data;
  }
}
