import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:our_chat/Screens/OurChat/Authentication/login_screen.dart';
import 'package:our_chat/Services/auth_services.dart';
import 'package:page_transition/page_transition.dart';

import 'MainScreens/bottom_bar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  Future<void> getData()  async {
    await AuthServices.getCurrentUser();
    await AuthServices.getAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    return FutureBuilder(
      future: getData().then((value) {
        Widget nextScreen = AuthServices.auth.currentUser == null
            ? const LoginScreen()
            : const BottomBar();
        Future.delayed(1000.ms, (){
          Navigator.pushReplacement(context, PageTransition(child: nextScreen, type: PageTransitionType.rightToLeft));
        });
      },),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
          case ConnectionState.none:
            return Scaffold(
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Welcome to OUR CHAT", style: TextStyle(color: Colors.deepPurple, fontSize: 20, fontWeight: FontWeight.w500),),
                  LottieBuilder.asset('assets/splash_animation.json', width: mq.width, height: mq.width,),
                  const Text("A Gift to Mumthaz 🤍❤", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            );
          case ConnectionState.active:
          case ConnectionState.done:
        }
        return Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Welcome to OUR CHAT", style: TextStyle(color: Colors.deepPurple, fontSize: 20, fontWeight: FontWeight.w500),),
              LottieBuilder.asset('assets/splash_animation.json', width: mq.width, height: mq.width,),
              const Text("A Gift to Mumthaz 🤍❤", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
            ],
          ),
        );
      }
    );
  }
}
