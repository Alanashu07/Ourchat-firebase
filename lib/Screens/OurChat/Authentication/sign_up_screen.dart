import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:our_chat/Screens/OurChat/Authentication/login_screen.dart';
import 'package:page_transition/page_transition.dart';
import '../../../Constants/alerts.dart';
import '../../../Services/auth_services.dart';
import '../../../Widgets/login_button.dart';
import '../../../Widgets/login_text_field.dart';
import '../splash_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool isSecurePassword = true;
  bool imageAdded = false;
  bool isLogging = false;
  XFile? image;
  String? imageUrl;
  bool isSecureConfirmPassword = true;
  final formKey = GlobalKey<FormState>();

  bool isValidEmail(String email) {
    final emailRegExp = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    return emailRegExp.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    imageAdded = image != null;
    final mq = MediaQuery.of(context).size;
    return Stack(
      children: [
        Scaffold(
            body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: mq.height * .05),
                  child: const Text(
                    "Welcome User",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const Text("Enter details to create your account",
                    style: TextStyle(color: Colors.black54, fontSize: 18)),
                imageAdded
                    ? Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final pickedImage = await picker.pickImage(
                                source: ImageSource.gallery);
                            if (pickedImage != null) {
                              setState(() {
                                image = pickedImage;
                              });
                            }
                          },
                          child: CircleAvatar(
                            radius: mq.width * .2,
                            backgroundImage: FileImage(File(image!.path)),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final pickedImage = await picker.pickImage(
                                source: ImageSource.gallery);
                            if (pickedImage != null) {
                              setState(() {
                                image = pickedImage;
                              });
                            }
                          },
                          child: CircleAvatar(
                            radius: mq.width * .2,
                            backgroundImage:
                                const AssetImage('images/group-chat.png'),
                          ),
                        ),
                      ),
                Form(
                    key: formKey,
                    child: Column(
                      children: [
                        LoginTextField(
                          textCapitalization: TextCapitalization.words,
                          controller: nameController,
                          hintText: 'Name',
                          suffixIcon: const Icon(
                            CupertinoIcons.person,
                            color: Colors.deepPurple,
                          ),
                        ),
                        LoginTextField(
                          textInputType: TextInputType.emailAddress,
                          controller: emailController,
                          textCapitalization: TextCapitalization.none,
                          hintText: 'Email Id',
                          suffixIcon: const Icon(
                            Icons.email_outlined,
                            color: Colors.deepPurple,
                          ),
                        ),
                        LoginTextField(
                          controller: passwordController,
                          hideText: isSecurePassword,
                          hintText: 'Password',
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  isSecurePassword = !isSecurePassword;
                                });
                              },
                              icon: Icon(
                                isSecurePassword
                                    ? CupertinoIcons.eye
                                    : CupertinoIcons.eye_slash,
                                color: Colors.deepPurple,
                              )),
                        ),
                        LoginTextField(
                          controller: confirmPasswordController,
                          hideText: isSecureConfirmPassword,
                          hintText: 'Confirm Password',
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  isSecureConfirmPassword =
                                      !isSecureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                isSecureConfirmPassword
                                    ? CupertinoIcons.eye
                                    : CupertinoIcons.eye_slash,
                                color: Colors.deepPurple,
                              )),
                        ),
                      ],
                    )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: LoginButton(
                    onTap: () async {
                      if (formKey.currentState!.validate() &&
                          passwordController.text ==
                              confirmPasswordController.text &&
                          imageAdded) {
                        if (isValidEmail(emailController.text)) {
                          try {
                            setState(() {
                              isLogging = true;
                            });
                            await AuthServices.auth
                                .createUserWithEmailAndPassword(
                                    email: emailController.text.trim(),
                                    password: passwordController.text);
                            final timeStamp =
                                DateTime.now().millisecondsSinceEpoch;
                            FirebaseStorage storage = FirebaseStorage.instance;
                            Reference ref = storage.ref().child(
                                'users/${AuthServices.auth.currentUser!.uid}/$timeStamp');
                            await ref.putFile(File(image!.path));
                            imageUrl = await ref.getDownloadURL();
                            AuthServices.userWithEmail(
                                context: context,
                                name: nameController.text.trim(),
                                password: passwordController.text,
                                email: emailController.text.trim(),
                                image: imageUrl!);
                            setState(() {
                              isLogging = false;
                            });
                            Navigator.pushReplacement(
                                context,
                                PageTransition(
                                    child: const SplashScreen(),
                                    type: PageTransitionType.rightToLeftJoined,
                                    childCurrent: const SignUpScreen()));
                            AuthServices.updateActiveStatus(true);
                          } on FirebaseAuthException catch (e) {
                            setState(() {
                              isLogging = false;
                            });
                            final msg = e.code;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(msg),
                              backgroundColor: Colors.deepPurple,
                            ));
                          }
                        } else {
                          showAlert(
                              context: context,
                              title: "Invalid email",
                              content:
                                  "Please enter a valid email to continue.");
                        }
                      } else if (passwordController.text.isEmpty) {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("Password is Empty"),
                                content: const Text("Password cannot be empty"),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("OK"))
                                ],
                              );
                            });
                      } else if (passwordController.text !=
                          confirmPasswordController.text) {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("Password don't match"),
                                content: const Text("Password do not match"),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("OK"))
                                ],
                              );
                            });
                      } else if (!imageAdded) {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("Image not provided"),
                                content: const Text(
                                    "Please proceed to add your image in order to continue. This is to verify genuineness of the application and the persons."),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("OK"))
                                ],
                              );
                            });
                      }
                    },
                    child: const Text(
                      "Sign up",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
                const Text(
                  "OR",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                GestureDetector(
                  onTap: () {
                    AuthServices.googleSignIn(context);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Continue with  ",
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                            color: Colors.deepPurple),
                      ),
                      Image.asset(
                        "images/social.png",
                        scale: 8,
                      )
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                        context,
                        PageTransition(
                            child: const LoginScreen(),
                            type: PageTransitionType.bottomToTopJoined,
                            childCurrent: const SignUpScreen()));
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?  ",
                        style: TextStyle(color: Colors.black),
                      ),
                      Text(
                        "Log in",
                        style: TextStyle(color: Colors.deepPurple),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: mq.height * .05,
                )
              ],
            ),
          ),
        )),
        isLogging
            ? Container(
                height: mq.height,
                width: mq.width,
                color: Colors.black38,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  color: Colors.deepPurple,
                ),
              )
            : const SizedBox()
      ],
    );
  }
}
