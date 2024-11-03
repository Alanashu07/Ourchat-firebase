import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:our_chat/Constants/date_format.dart';
import 'package:our_chat/Screens/OurChat/splash_screen.dart';
import 'package:our_chat/Screens/image_viewer.dart';
import 'package:our_chat/Services/auth_services.dart';
import 'package:our_chat/Widgets/Notepad/custom_text_field.dart';
import 'package:our_chat/Widgets/login_button.dart';
import 'package:our_chat/Widgets/open_item.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Size mq = MediaQuery.of(context).size;
    final user = context.watch<AuthServices>().user;
    TextEditingController nameController = TextEditingController();
    TextEditingController aboutController = TextEditingController();
    nameController.text = user.name;
    aboutController.text = user.about;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              SizedBox(
                height: mq.height * .1,
              ),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  OpenItem(
                    openChild: ImageViewer(title: user.name, image: user.image),
                    closedChild: SizedBox(
                      width: 140,
                      height: 140,
                      child: ClipOval(
                          child: CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: user.image,
                            placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                          )),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedFile =
                      await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        final timeStamp = DateTime.now().millisecondsSinceEpoch;
                        FirebaseStorage storage = FirebaseStorage.instance;
                        Reference ref =
                        storage.ref().child('users/${user.id}/$timeStamp');
                        await ref.putFile(File(pickedFile.path));
                        String imageUrl = await ref.getDownloadURL();
                        await AuthServices.updateUser(
                            user: user,
                            name: nameController.text.trim(),
                            newAbout: aboutController.text.trim(),
                            newImage: imageUrl);
                        context.read<AuthServices>().updateUserLocally(
                            name: nameController.text.trim(),
                            newAbout: aboutController.text.trim(),
                            newImage: imageUrl);
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 15,
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: mq.height * .03,
              ),
              Text(
                user.email,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              SizedBox(
                height: mq.height * .03,
              ),
              CustomTextField(
                controller: nameController,
                hintText: "Enter your name",
                textInputType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                prefixIcon: const Icon(Icons.person, color: Colors.deepPurple,),
              ),
              SizedBox(
                height: mq.height * .02,
              ),
              CustomTextField(
                controller: aboutController,
                hintText: "Enter your about",
                textInputType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                prefixIcon: const Icon(Icons.info, color: Colors.deepPurple,),
              ),
              SizedBox(height: mq.height*.05,),
              LoginButton(onTap: () async {
                context.read<AuthServices>().updateUserLocally(
                    name: nameController.text.trim(),
                    newAbout: aboutController.text.trim(),
                    newImage: user.image);
                await AuthServices.updateUser(
                    user: user,
                    name: nameController.text.trim(),
                    newAbout: aboutController.text.trim(),
                    newImage: user.image);
              }, width: mq.width / 2, child: const Text("Update", style: TextStyle(color: Colors.white),),),
              SizedBox(height: mq.height*.05,),
              Text('Joined On: ${DateFormat.getCreatedTime(context: context, time: user.joinedOn)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple),),
              SizedBox(height: mq.height*.05,),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await AuthServices.updateActiveStatus(false);
          await FirebaseAuth.instance.signOut();
          await GoogleSignIn().signOut();
          Navigator.pushReplacement(
              context,
              PageTransition(
                  child: const SplashScreen(),
                  type: PageTransitionType.rightToLeft));
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(
          Icons.logout,
          color: Colors.white,
        ),
      ),
    );
  }
}
