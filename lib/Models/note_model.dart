class Note {
  late String title;
  late String content;
  late String time;
  late int? id;

  Note({required this.title, required this.content, required this.time, this.id});

  Note.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    content = json['content'];
    time = json['time'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic> {};
    data['title'] = title;
    data['content'] = content;
    data['time'] = time;
    data['id'] = id;
    return data;
  }
}