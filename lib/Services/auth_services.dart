import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:our_chat/Models/status_model.dart';
import '../Constants/alerts.dart';
import '../Constants/date_format.dart';
import '../Models/user_model.dart' as user_model;
import '../Screens/OurChat/splash_screen.dart';

class AuthServices extends ChangeNotifier {
  static String usersCollection = 'users';
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  static Future<void> getAllUsers() async {
    try {
      QuerySnapshot snapshot =
          await firestore.collection(usersCollection).get();
      users = snapshot.docs
          .map(
              (e) => user_model.User.fromJson(e.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void updateCurrentUserStatusCount({required int index, required List<String> users}) {
    currentUser.status[index].users = users;
    notifyListeners();
  }

  static List<user_model.User> users = [];

  List<user_model.User> get allUsers => users;

  static Future<user_model.User?> getCurrentUser() async {
    if (auth.currentUser != null) {
      final userData = await firestore
          .collection(usersCollection)
          .doc(auth.currentUser!.uid)
          .get();
      user_model.User user = user_model.User.fromJson(userData.data()!);
      currentUser = user;
      await getFirebaseMessagingToken();
      return user;
    } else {
      return null;
    }
  }

  static late user_model.User currentUser;

  user_model.User get user => currentUser;

  static Future googleSignIn(BuildContext context) async {
    try {
      final google = GoogleSignIn();
      final user = await google.signIn();
      if (user == null) return;
      final auth = await user.authentication;
      final credential = GoogleAuthProvider.credential(
          idToken: auth.idToken, accessToken: auth.accessToken);
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (await userExists()) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const SplashScreen()));
        updateActiveStatus(true);
      } else {
        await createUser(context).then(
          (value) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const SplashScreen()));
            updateActiveStatus(true);
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.code;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ));
    }
  }

  static Future forgotPassword(
      {required BuildContext context, required String email}) async {
    try {
      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please Enter your email ID")));
      } else {
        if (await userExists()) {
          FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("User with this email is not found!")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  static signInWithEmail(
      {required BuildContext context,
      required bool isValidEmail,
      required String email,
      required String password}) async {
    if (isValidEmail) {
      try {
        await auth.signInWithEmailAndPassword(email: email, password: password);
        if (await userExists()) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const SplashScreen()));
          updateActiveStatus(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('User not found! Please try signing in')));
        }
      } on FirebaseAuthException catch (e) {
        final msg = e.code;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ));
      }
    } else {
      showAlert(
          context: context,
          title: "Invalid Email",
          content: "Please enter a valid email to continue");
    }
  }

  static Future<bool> userExists() async {
    return (await firestore
            .collection(usersCollection)
            .doc(auth.currentUser!.uid)
            .get())
        .exists;
  }

  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();
    await fMessaging.getToken().then((value) {
      if (value != null) {
        firestore.collection(usersCollection).doc(auth.currentUser!.uid).update({
          'token': value
        });
        currentUser.token = value;
      }
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUserId() {
    return firestore
        .collection(usersCollection)
        .doc(auth.currentUser!.uid)
        .collection('my_users')
        .snapshots();
  }

  static Future<void> deleteStatus(Status status) async {
    await firestore.collection(usersCollection).doc(currentUser.id).update({
      'status': FieldValue.arrayRemove([status.toJson()])
    });
  }

  void deleteStatusLocally(Status status) {
    currentUser.status.removeWhere((s) => s.id == status.id);
    notifyListeners();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsersFromFB(
      List<String> userIds) {
    return firestore
        .collection(usersCollection)
        .where('id', whereIn: userIds)
        .snapshots();
  }

  static Future<void> addNewUser({required user_model.User user}) async {
    await firestore
        .collection(usersCollection)
        .doc(auth.currentUser!.uid)
        .collection('my_users')
        .doc(user.id)
        .set({});
  }

  static Future<void> sendFirstMessage(
      {required user_model.User chatUser}) async {
    await firestore
        .collection(usersCollection)
        .doc(auth.currentUser!.uid)
        .collection('my_users')
        .doc(chatUser.id)
        .set({});
    await firestore
        .collection(usersCollection)
        .doc(chatUser.id)
        .collection('my_users')
        .doc(auth.currentUser!.uid)
        .set({});
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      user_model.User chatUser) {
    return firestore
        .collection(usersCollection)
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> listenToUser() {
    return
        firestore.collection(usersCollection).doc(currentUser.id).snapshots();
  }

  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection(usersCollection).doc(auth.currentUser?.uid).update({
      'isOnline': isOnline,
      'lastActive': DateFormat.getNow(),
      'token': currentUser.token
    });
  }

  static Future<void> deleteOldStatusUpdates(String userId) async {
    final snapshot = await firestore.collection('users').doc(userId).get();

    final List<dynamic> statusUpdates = snapshot.data()!['status'];

    final DateTime now = DateTime.now();

    for (var statusUpdate in statusUpdates) {
      final DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(statusUpdate['time']));

      final Duration timeDifference = now.difference(timestamp);

      if (timeDifference.inHours >= 24) {
        await firestore.collection(usersCollection).doc(userId).update({
          'status': FieldValue.arrayRemove([statusUpdate]),
        });
      }
    }
    await getCurrentUser();
  }

  static Future<void> createUser(BuildContext context) async {
    final user = user_model.User(
      password: '',
      id: auth.currentUser!.uid,
      name: auth.currentUser!.displayName ?? '',
      email: auth.currentUser!.email ?? '',
      image: auth.currentUser!.photoURL ?? '',
      isOnline: false,
      joinedOn: DateFormat.getNow(),
      lastActive: DateFormat.getNow(),
      token: '',
      status: [],
      about: 'Feeling Loved with OUR CHAT!💕',
    );

    return await firestore
        .collection(usersCollection)
        .doc(auth.currentUser!.uid)
        .set(user.toJson());
  }

  static Future<void> updateUser(
      {required user_model.User user,
      required String name,
      required String newAbout,
      required String newImage}) async {

    return await firestore
        .collection(usersCollection)
        .doc(user.id)
        .update({
      'name': name,
      'about': newAbout,
      'image': newImage,
    });
  }

  void updateUserLocally(
      {required String name,
      required String newAbout,
      required String newImage}) {
    currentUser.name = name;
    currentUser.about = newAbout;
    currentUser.image = newImage;
    notifyListeners();
  }

  static Future<void> viewStatus({required user_model.User user, required Status status}) async {
    final snap = await firestore.collection(usersCollection).doc(user.id).get();
    final List<Status> statuses = (snap.data()!['status'] as List).map((e) => Status.fromJson(e)).toList();
    final newStatusIndex = statuses.indexWhere((element) => element.id == status.id);
    if (!statuses[newStatusIndex].users.contains(currentUser.id)) {
      statuses[newStatusIndex].users.add(currentUser.id);
    }
    await firestore.collection(usersCollection).doc(user.id).update({
      'status': statuses.map((s) => s.toJson()).toList()
    });
  }

  static Future<void> updateUserStatus({required Status status}) async {
    return await firestore
        .collection(usersCollection)
        .doc(currentUser.id)
        .update({
      'status': FieldValue.arrayUnion([status.toJson()])
    });
  }

  void updateUserStatusLocally({required Status status}) {
    currentUser.status.add(status);
    notifyListeners();
  }

  static Future<void> userWithEmail(
      {required String name,
      required BuildContext context,
      required String password,
      required String email,
      required String image}) async {
    final user = user_model.User(
      id: auth.currentUser!.uid,
      name: name,
      email: auth.currentUser!.email ?? '',
      password: password,
      image: image,
      isOnline: false,
      joinedOn: DateFormat.getNow(),
      lastActive: DateFormat.getNow(),
      token: '',
      status: [],
      about: 'Feeling Loved with OUR CHAT!💕',
    );

    return await firestore
        .collection(usersCollection)
        .doc(auth.currentUser!.uid)
        .set(user.toJson());
  }
}
