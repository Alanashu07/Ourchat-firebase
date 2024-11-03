import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:our_chat/Services/NotificationServices/notification_services.dart';
import '../Constants/date_format.dart';
import '../Models/message_model.dart';
import '../Models/user_model.dart' as user_model;

class MessageServices {
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseAuth auth = FirebaseAuth.instance;

  static String messagesCollection = 'chats';

  static String getConversationId(String id) =>
      auth.currentUser!.uid.hashCode <= id.hashCode
          ? '${auth.currentUser!.uid}_$id'
          : '${id}_${auth.currentUser!.uid}';

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      user_model.User user) {
    return firestore
        .collection(
            '$messagesCollection/${getConversationId(user.id)}/messages/')
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getLimitedMessages(
      user_model.User user, int limit) {
    return firestore
        .collection(
            '$messagesCollection/${getConversationId(user.id)}/messages/')
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  static Future<Message?> getTaggedMessage(String id, user_model.User chatUser) async {
    final snap = await firestore
        .collection('$messagesCollection/${getConversationId(chatUser.id)}/messages/')
        .where('id', isEqualTo: id)
        .get();
    final data = snap.docs;
    final list =
        data.map((e) => Message.fromJson(e.data())).toList();
    final message = list.isNotEmpty ? list[0] : null;
    return message;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      user_model.User user) {
    return firestore
        .collection(
            '$messagesCollection/${getConversationId(user.id)}/messages/')
        .orderBy('sentAt', descending: true)
        .limit(1)
        .snapshots();
  }

  static Future<void> sendMessage(
      user_model.User chatUser, Message message) async {
    final ref = firestore.collection(
        '$messagesCollection/${getConversationId(chatUser.id)}/messages/');
    Message initMessage = message;
    initMessage.isUploaded = false;
    await ref.doc(message.id).set(initMessage.toJson());
    await ref.doc(message.id).update({'isUploaded': true});
    await NotificationServices.sendPushNotification(user: chatUser, message: message);
  }

  static Future<void> updateReadStatus(Message message) async {
    firestore
        .collection(
            '$messagesCollection/${getConversationId(message.sender)}/messages/')
        .doc(message.id)
        .update({
      'readAt': DateFormat.getNow(),
    });
  }
}
