import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:our_chat/Constants/alerts.dart';
import 'package:our_chat/Screens/OurChat/splash_screen.dart';
import 'package:our_chat/Services/chat_lock.dart';
import 'package:our_chat/Widgets/Notepad/custom_text_field.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  TextEditingController pinController = TextEditingController();
  TextEditingController confirmPIN = TextEditingController();
  bool isLocked = false;
  bool securePIN = true;

  @override
  void initState() {
    ChatLock.getCurrentLock();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final chatLock = context.watch<ChatLock>().lock;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Lock Screen"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            chatLock == null
                ? !isLocked
                    ? Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: CustomTextField(
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  securePIN = !securePIN;
                                });
                              },
                              icon: Icon(securePIN
                                  ? CupertinoIcons.eye
                                  : CupertinoIcons.eye_slash)),
                          hideText: securePIN,
                          textAlign: TextAlign.center,
                          controller: pinController,
                          hintText: "Enter New PIN",
                          textInputType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          onSubmitted: (value) {
                            if (value.length == 4) {
                              setState(() {
                                isLocked = true;
                              });
                            } else {
                              showSnackBar(
                                  context: context,
                                  content: "PIN must be 4 digits",
                                  color: Colors.red);
                            }
                          },
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: CustomTextField(
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  securePIN = !securePIN;
                                });
                              },
                              icon: Icon(securePIN
                                  ? CupertinoIcons.eye
                                  : CupertinoIcons.eye_slash)),
                          hideText: securePIN,
                          textAlign: TextAlign.center,
                          autofocus: true,
                          controller: confirmPIN,
                          hintText: "Confirm Your PIN",
                          textInputType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          onSubmitted: (value) async {
                            if (pinController.text == confirmPIN.text) {
                              await context.read<ChatLock>().setLock(value);
                              setState(() {
                                pinController.clear();
                                confirmPIN.clear();
                                isLocked = false;
                              });
                            } else {
                              showSnackBar(
                                  context: context,
                                  content: "PIN Does not match",
                                  color: Colors.red);
                              setState(() {
                                pinController.clear();
                                confirmPIN.clear();
                                isLocked = false;
                              });
                            }
                          },
                        ),
                      )
                : Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: CustomTextField(
                      suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              securePIN = !securePIN;
                            });
                          },
                          icon: Icon(securePIN
                              ? CupertinoIcons.eye
                              : CupertinoIcons.eye_slash)),
                      hideText: securePIN,
                      textAlign: TextAlign.center,
                      controller: pinController,
                      hintText: "Enter Your PIN",
                      textInputType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4)
                      ],
                      onSubmitted: (value) async {
                        if (value == chatLock) {
                          Navigator.pushReplacement(
                              context,
                              PageTransition(
                                  child: const SplashScreen(),
                                  type: PageTransitionType.bottomToTop));
                        } else {
                          pinController.clear();
                          showSnackBar(
                              context: context,
                              content: "Wrong PIN",
                              color: Colors.red);
                        }
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
