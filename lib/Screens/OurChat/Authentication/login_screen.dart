import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:our_chat/Screens/OurChat/Authentication/sign_up_screen.dart';
import 'package:our_chat/Services/auth_services.dart';
import 'package:page_transition/page_transition.dart';
import '../../../Widgets/login_button.dart';
import '../../../Widgets/login_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isSecurePassword = true;
  dynamic userTest;
  final formKey = GlobalKey<FormState>();

  bool isValidEmail(String email) {
    final emailRegExp = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    return emailRegExp.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: mq.height * .03,
              ),
              Container(
                height: mq.height * .35,
                alignment: Alignment.topCenter,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                      image: AssetImage("images/chatting person.png"), fit: BoxFit.cover),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 18.0),
                child: Text(
                  "Welcome Back",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const Text("Enter details to get back your account",
                  style: TextStyle(color: Colors.black54, fontSize: 18)),
              Form(
                  key: formKey,
                  child: Column(
                    children: [
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
                    ],
                  )),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                      onPressed: () {
                        AuthServices.forgotPassword(context: context, email: emailController.text.trim());
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 18,
                            fontWeight: FontWeight.w500),
                      ))
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: LoginButton(
                  onTap: () {
                    formKey.currentState!.save();
                    if (formKey.currentState!.validate()) {
                      AuthServices.signInWithEmail(context: context, isValidEmail: isValidEmail(emailController.text.trim()), email: emailController.text.trim(), password: passwordController.text.trim());
                    }
                  },
                  child: const Text(
                    "Login",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
              SizedBox(
                height: mq.height * .01,
              ),
              const Center(
                child: Text(
                  "OR",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ),
              GestureDetector(
                onTap: ()async {
                  await AuthServices.googleSignIn(context);
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
              SizedBox(
                height: mq.height * .01,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      PageTransition(
                          child: const SignUpScreen(),
                          type: PageTransitionType.bottomToTopJoined,
                          childCurrent: const LoginScreen()));
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?  ",
                      style: TextStyle(color: Colors.black),
                    ),
                    Text(
                      "Sign up",
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
