import 'package:our_chat/Models/user_model.dart';

class Status {
  late String url;
  late String id;
  late String type;
  late String time;
  String? caption;
  late List<String> users;

  Status({required this.url, required this.id, required this.type, required this.time, required this.users, this.caption});


  Status.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    id = json['id'];
    type = json['type'];
    time = json['time'];
    caption = json['caption'];
    users = json['users'].cast<String>() ?? [];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic> {};
    data['url'] = url;
    data['id'] = id;
    data['type'] = type;
    data['time'] = time;
    data['caption'] = caption;
    data['users'] = users;
    return data;
  }
}