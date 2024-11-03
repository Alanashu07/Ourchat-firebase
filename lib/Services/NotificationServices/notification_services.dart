import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:our_chat/Models/message_model.dart';
import 'package:our_chat/Models/user_model.dart';
import 'package:our_chat/Services/auth_services.dart';

class NotificationServices {

  static FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;


  static Future<String> getAccessToken() async {
    final servicesAccountJson = {

    };

    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(servicesAccountJson),
      scopes,
    );

    auth.AccessCredentials credentials = await auth.obtainAccessCredentialsViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(servicesAccountJson),
      scopes,
      client
    );

    client.close();
    return credentials.accessToken.data;
  }

  static sendPushNotification({required User user, required Message message}) async {
    try{
      final String serverKey = await getAccessToken();
      String fcmUrl = 'https://fcm.googleapis.com/v1/projects/our-chat-cc2f5/messages:send';

      final Map<String, dynamic> notification = message.type == 'image' ? {
        'message': {
          'token': user.token,
          'notification': {
            'title': AuthServices.currentUser.name,
            'body': 'Sent an Image 📸',
            'image': message.text
          },
          'data': {
            'user_id': AuthServices.currentUser.id
          }
        }
      } :{
        'message': {
          'token': user.token,
          'notification': {
            'title': AuthServices.currentUser.name,
            'body': message.type == 'image'
                ? 'Sent an Image 📸'
                : message.type == 'video'
                ? 'Sent a Video 🎥'
                : message.type == 'gif'
                ? 'Send a gif 💕'
                : message.text,
          },
          'data': {
            'user_id': AuthServices.currentUser.id
          }
        }
      };

      await http.post(
        Uri.parse(fcmUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverKey',
        },
        body: jsonEncode(notification),
      );
    } catch(e) {
      if(kDebugMode) {
        print(e);
      }
    }
  }
}
