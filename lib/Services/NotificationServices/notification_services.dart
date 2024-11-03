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
      "type": "service_account",
      "project_id": "our-chat-cc2f5",
      "private_key_id": "c2ec065c175c731c1372dfbb2a31639a41e535fa",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDJVFmrDrmH2sTo\nyyEptQELmfj1p+MnL44Q5hMxq6WWz0gjs+eOGD7zsUGsT5H9hddbQHeyMS93ba7e\nNIH/b2+MXkYX3Uzdta+CETj5/4tIn2Uja2bZYS98tcDydM5ZeweOmnPpZtl8sAgc\nx9RK/WDB9YiGT2cqJFf1t2S/rVOyTwJkkqascblNCaiJZAwOzAL4QnpxXqebw5Zs\nZIQOTLf/1ruaWnxepJHg7e1a/iRJw5KMcCUMo13T+nfEKVdmzQHT+2P4SOcp3J2/\ng7RRxwYHGqIHCfAGZj+FU0nPinD2oraHu74OjZdi/4fwy1uLUgqydU9m7JkwxNG6\nypIYAw3TAgMBAAECggEAUSDddVHcr4MXwBtCxNS8lBk6unspzPubyvF7oJNjic8D\naeewEpFwpLC0HyR9VuUdMBddZH/vebfINKCCFhWopK7Eng8+T0VMcSRRimRQkzYw\nAkLgUg6YnS98jfdFw8cQ94UD2nTohRdGXZqk0Icj+2Te3AiZMOEuVMTPI3JL/Nik\nj9Kg6+0+5owrKR49YlGCOt0X435OZdvl3xq065uxqqh0f7ta6MPLWSTOLxUBzCFT\nB0+tTl0T/zwcBMBk8oCVJPjXNnB2opc0CDR1ZnsfMHBG/IqBsdk0mBPcDoBQofAG\nAFcJewYK3vMiuVWdXH39TG8Nml9xxH/mvVMsiFKVEQKBgQDu9kQqk57I4Szq9Bw9\nqWkwqGjDlcJc11guKrSPgnFeh5ScInzUQfJ0U+9jM9hsTPMeKUGrP+X1kj7gTPRl\nZj4wKEL9pamiGn4rK8g4vGZFRRTpSQbGWkKYzjKo5AJPdhLJ05e+wcnjSOE+mEwm\npRjCGP0hcWL3W99Frv1U2Ahr2wKBgQDXry83KPFjfLWNSVicNN7J2v18fw2zBWI1\n6F1CJBv5eFC12ptf+H4oAsVVi+bE6uYyLGzFXwXzflii4tnY4JBLv1cmq+JyNm0g\nn3T5kB5xGYDOxJvk1ZIqF0FQeAS45Tl8nzsjRcA5eiw6qjiNbjZ5dg4Z9PwQg7Iw\nDRAPH2XDaQKBgAeJZt785u4pA/SpHFbph/LL7Pn2ODobZKGYITfBgnfbyNkf0VYU\nemQm3Y8AbJwF1UknPfX7vvH+2dLTOoYUMnPsYSiE2BPPyBjueZMohgU7R4yQDBGn\neSA+qKRhBJ2i+La64LdYf1iWzNvfi89QN7aveRRb8iYhFKqq+Tx6z9EvAoGAU4of\nF5ZcKNSc3WSTVa2EvVp85EOx4q0rJQYjWQLzcuUPHeDWXY26D3VDSacucwcosjZS\nyv/LJkzBuBV1m3MfcLdj4i6hPuulyQT6Ic+YeuYN5ghw+Wlfe74WJjzWV2cxpPtn\nxHm3wot3piFYVi9iGhmHzLX/C8Z2tfXZSoI2wEECgYBW9xPyxsLCNbH6iYhQd7D3\naoyTMeHgXh/1y774KdyTjyIRGI57tmiz6NlCP/25CtGMk3Xx+5jpOR4ic+lKBxAk\n7KJIe3L+0THVGT913kmQgXjodjIQ5aS9Cd6pb+EYjihYc1dqbcVGmAh8vvW7Kzwx\nLJq/Lu3OfRNFz8856pV/+Q==\n-----END PRIVATE KEY-----\n",
      "client_email": "notepad-ourchat@our-chat-cc2f5.iam.gserviceaccount.com",
      "client_id": "111334448701114560618",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/notepad-ourchat%40our-chat-cc2f5.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
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