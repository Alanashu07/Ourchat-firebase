
class Message{
  late String id;
  late String sender;
  late String receiver;
  late String text;
  late String sentAt;
  late String readAt;
  late String type;
  bool? isUploaded;
  String? taggedMessage;
  bool? isTagged;
  String? tagType;

  Message({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.text,
    required this.sentAt,
    required this.readAt,
    required this.type,
    this.isUploaded = false,
    this.taggedMessage,
    this.isTagged,
    this.tagType,
  });

  Message.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sender = json['sender'];
    receiver = json['receiver'];
    text = json['text'];
    sentAt = json['sentAt'];
    readAt = json['readAt'];
    isUploaded = json['isUploaded'];
    type = json['type'];
    taggedMessage = json['taggedMessage'];
    isTagged = json['isTagged'];
    tagType = json['tagType'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['sender'] = sender;
    data['receiver'] = receiver;
    data['text'] = text;
    data['isUploaded'] = isUploaded;
    data['sentAt'] = sentAt;
    data['readAt'] = readAt;
    data['type'] = type;
    data['taggedMessage'] = taggedMessage;
    data['isTagged'] = isTagged;
    data['tagType'] = tagType;
    return data;
  }

}