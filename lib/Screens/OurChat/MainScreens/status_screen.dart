import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:our_chat/Constants/date_format.dart';
import 'package:our_chat/Models/status_model.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '../../../Models/user_model.dart';
import '../../../Services/auth_services.dart';
import '../../../Widgets/OurChat/my_status.dart';
import '../../../Widgets/OurChat/recent_status.dart';
import '../upload_status.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  List<User> users = [];
  List<User> viewedUpdates = [];
  List<User> recentUpdates = [];
  bool sending = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthServices>().user;
    final mq = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: StreamBuilder(
                stream: AuthServices.getMyUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text(
                      "No Updates yet!",
                      style: TextStyle(color: Colors.deepPurple, fontSize: 20),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }
                  if (snapshot.data!.docs.isEmpty) {
                    return const Text("No User Data available");
                  }
                  return StreamBuilder(
                      stream: AuthServices.getAllUsersFromFB(
                          snapshot.data?.docs.map((e) => e.id).toList() ?? []),
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                          case ConnectionState.none:
                            return const Center(
                              child: CircularProgressIndicator(),
                            );

                          case ConnectionState.active:
                          case ConnectionState.done:
                            final data = snapshot.data?.docs;
                            List<User> fetchedUsers = data
                                    ?.map((e) => User.fromJson(e.data()))
                                    .toList() ??
                                [];
                            users = fetchedUsers
                                .where(
                                  (element) => element.status.isNotEmpty,
                                )
                                .toList();
                            viewedUpdates = users
                                .where(
                                  (element) =>
                                      element.status.every((item) => item.users
                                          .contains(currentUser.id)) ==
                                      true,
                                )
                                .toList();
                            recentUpdates = users
                                .where(
                                  (element) => !viewedUpdates.contains(element),
                                )
                                .toList();
                        }
                        return Column(
                          children: [
                            const SizedBox(
                              height: 15,
                            ),
                            MyStatus(
                              onTap: () async {
                                await uploadImageCamera(
                                    user: currentUser, context: context);
                              },
                            ),
                            if (recentUpdates.isNotEmpty)
                              Container(
                                alignment: Alignment.centerLeft,
                                height: 30,
                                width: mq.width,
                                color: Colors.grey[300],
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: const Text(
                                  "Recent Updates",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                            ListView.separated(
                              separatorBuilder: (context, index) => const Divider(),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: recentUpdates.length,
                                itemBuilder: (context, index) {
                                  recentUpdates.sort((b, a) => a
                                      .status[a.status.length - 1].time
                                      .compareTo(
                                          b.status[b.status.length - 1].time));
                                  return RecentStatus(
                                    user: recentUpdates[index],
                                  );
                                }),
                            if (viewedUpdates.isNotEmpty)
                              Container(
                                alignment: Alignment.centerLeft,
                                height: 30,
                                width: mq.width,
                                color: Colors.grey[300],
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: const Text(
                                  "Viewed Updates",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                            ListView.separated(
                                separatorBuilder: (context, index) => const Divider(),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: viewedUpdates.length,
                                itemBuilder: (context, index) {
                                  viewedUpdates.sort((b, a) => a
                                      .status[a.status.length - 1].time
                                      .compareTo(
                                          b.status[b.status.length - 1].time));
                                  return RecentStatus(
                                    user: viewedUpdates[index],
                                  );
                                }),
                          ],
                        );
                      });
                }),
          ),
          if (sending)
            Container(
              alignment: Alignment.center,
              height: mq.height,
              width: mq.width,
              child: CircularProgressIndicator(),
            )
        ],
      ),
      floatingActionButton: SpeedDial(
        backgroundColor: Colors.deepPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        activeIcon: Icons.close,
        foregroundColor: Colors.white,
        children: [
          SpeedDialChild(
            onTap: () async {
              await uploadImageGallery(user: currentUser, context: context);
            },
            labelWidget: const Text(
              "Upload Image from Gallery   ",
              style: TextStyle(color: Colors.black54),
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            backgroundColor: Colors.deepPurple,
            child: const Icon(
              Icons.insert_photo,
              color: Colors.white,
            ),
          ),
          SpeedDialChild(
            onTap: () async {
              await uploadImageCamera(user: currentUser, context: context);
            },
            labelWidget: const Text("Upload Image from Camera   ",
                style: TextStyle(color: Colors.black54)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            backgroundColor: Colors.deepPurple,
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
            ),
          ),
          SpeedDialChild(
            onTap: () async {
              await uploadVideoGallery(user: currentUser, context: context);
            },
            labelWidget: const Text("Upload Video from Gallery   ",
                style: TextStyle(color: Colors.black54)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            backgroundColor: Colors.deepPurple,
            child: const Icon(
              Icons.video_camera_back,
              color: Colors.white,
            ),
          ),
          SpeedDialChild(
            onTap: () async {
              await uploadVideoCamera(user: currentUser, context: context);
            },
            labelWidget: const Text("Upload Video from Camera   ",
                style: TextStyle(color: Colors.black54)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            backgroundColor: Colors.deepPurple,
            child: const Icon(
              Icons.video_call,
              color: Colors.white,
            ),
          ),
        ],
        child: const Icon(Icons.add),
      ),
    );
  }

  uploadImageCamera({required User user, required BuildContext context}) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        sending = true;
      });
      final timeStamp = DateTime.now().millisecondsSinceEpoch;
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child('users/${user.id}/status/$timeStamp');
      await ref.putFile(File(image.path));
      String imageUrl = await ref.getDownloadURL();
      Navigator.push(
          context,
          PageTransition(
              child: UploadStatus(
                type: 'image',
                url: imageUrl,
                id: 'status-${user.id}-$timeStamp',
              ),
              type: PageTransitionType.bottomToTop));
      setState(() {
        sending = false;
      });
    }
  }

  uploadImageGallery(
      {required User user, required BuildContext context}) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        sending = true;
      });
      final timeStamp = DateTime.now().millisecondsSinceEpoch;
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child('users/${user.id}/status/$timeStamp');
      await ref.putFile(File(image.path));
      String imageUrl = await ref.getDownloadURL();
      Navigator.push(
          context,
          PageTransition(
              child: UploadStatus(
                type: 'image',
                url: imageUrl,
                id: 'status-${user.id}-$timeStamp',
              ),
              type: PageTransitionType.bottomToTop));
      setState(() {
        sending = false;
      });
    }
  }

  uploadVideoCamera({required User user, required BuildContext context}) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickVideo(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        sending = true;
      });
      final timeStamp = DateTime.now().millisecondsSinceEpoch;
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child('users/${user.id}/status/$timeStamp');
      await ref.putFile(File(image.path));
      String imageUrl = await ref.getDownloadURL();
      Navigator.push(
          context,
          PageTransition(
              child: UploadStatus(
                type: 'video',
                url: imageUrl,
                id: 'status-${user.id}-$timeStamp',
              ),
              type: PageTransitionType.bottomToTop));
      setState(() {
        sending = false;
      });
    }
  }

  uploadVideoGallery(
      {required User user, required BuildContext context}) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickVideo(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        sending = true;
      });
      final timeStamp = DateTime.now().millisecondsSinceEpoch;
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child('users/${user.id}/status/$timeStamp');
      await ref.putFile(File(image.path));
      String imageUrl = await ref.getDownloadURL();
      Navigator.push(
          context,
          PageTransition(
              child: UploadStatus(
                type: 'video',
                url: imageUrl,
                id: 'status-${user.id}-$timeStamp',
              ),
              type: PageTransitionType.bottomToTop));
      setState(() {
        sending = false;
      });
    }
  }
}
