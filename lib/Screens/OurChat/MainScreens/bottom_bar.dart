import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:our_chat/Constants/alerts.dart';
import 'package:our_chat/Screens/OurChat/MainScreens/chat_home.dart';
import 'package:our_chat/Screens/OurChat/MainScreens/profile_screen.dart';
import 'package:our_chat/Screens/OurChat/MainScreens/status_screen.dart';
import 'package:our_chat/Screens/OurChat/search_screen.dart';
import 'package:our_chat/Services/auth_services.dart';
import 'package:our_chat/Services/chat_lock.dart';
import 'package:our_chat/Widgets/Notepad/custom_text_field.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

import '../../../Models/user_model.dart';

final navigationKey = GlobalKey<CurvedNavigationBarState>();

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  TextEditingController oldPIN = TextEditingController();
  TextEditingController newPIN = TextEditingController();
  TextEditingController confirmPIN = TextEditingController();

  void changePIN(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        bool secureOldPIN = true;
        bool securePIN = true;
        bool secureConfirmPIN = true;
        String chatLock = context.watch<ChatLock>().lock!;
        return AlertDialog(
          title: const Text('Change PIN'),
          content: StatefulBuilder(builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: oldPIN,
                  hintText: 'Old Pin Number',
                  suffixIcon: IconButton(
                      onPressed: () {
                        state(() {
                          secureOldPIN = !secureOldPIN;
                        });
                      },
                      icon: Icon(secureOldPIN
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash)),
                  hideText: secureOldPIN,
                  textAlign: TextAlign.center,
                  textInputType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                CustomTextField(
                  controller: newPIN,
                  hintText: 'New Pin Number',
                  suffixIcon: IconButton(
                      onPressed: () {
                        state(() {
                          securePIN = !securePIN;
                        });
                      },
                      icon: Icon(securePIN
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash)),
                  hideText: securePIN,
                  textAlign: TextAlign.center,
                  textInputType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                CustomTextField(
                  controller: confirmPIN,
                  hintText: 'Confirm Pin Number',
                  suffixIcon: IconButton(
                      onPressed: () {
                        state(() {
                          secureConfirmPIN = !secureConfirmPIN;
                        });
                      },
                      icon: Icon(secureConfirmPIN
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash)),
                  hideText: secureConfirmPIN,
                  textAlign: TextAlign.center,
                  textInputType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
              ],
            );
          }),
          actions: [
            TextButton(
                onPressed: () async {
                  if (oldPIN.text == chatLock &&
                      newPIN.text == confirmPIN.text &&
                      newPIN.text.length == 4) {
                    Navigator.pop(context);
                    await context.read<ChatLock>().setLock(newPIN.text);
                    oldPIN.clear();
                    newPIN.clear();
                    confirmPIN.clear();
                    showSnackBar(
                        context: context,
                        content: "PIN Changed Successfully",
                        color: Colors.green);
                  } else if (oldPIN.text != chatLock) {
                    showAlert(
                        context: context,
                        title: "Wrong PIN",
                        content: "Please enter correct Pin to change.");
                  } else if (newPIN.text != confirmPIN.text) {
                    showAlert(
                        context: context,
                        title: "PIN Mismatch",
                        content:
                            "Pin and confirm Pin does note match. Please try again.");
                  } else if (newPIN.text.length != 4) {
                    showAlert(
                        context: context,
                        title: "Invalid PIN",
                        content:
                            "PIN must be 4 digits long. Please try again.");
                  }
                },
                child: const Text("Submit")),
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  oldPIN.clear();
                  newPIN.clear();
                  confirmPIN.clear();
                },
                child: const Text("Cancel")),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    deleteOldStatus();
    AuthServices.getCurrentUser();
    ChatLock.getWallpaper();
    ChatLock.getCurrentLock();
    AuthServices.updateActiveStatus(true);
    SystemChannels.lifecycle.setMessageHandler(
      (message) {
        if (message!.contains("resumed")) {
          AuthServices.updateActiveStatus(true);
        } else {
          AuthServices.updateActiveStatus(false);
        }
        return Future.value(message);
      },
    );
    super.initState();
  }

  deleteOldStatus() async {
    final users = AuthServices.users;
    for (var user in users) {
      AuthServices.deleteOldStatusUpdates(user.id);
    }
  }

  List<Widget> screens = [
    const ChatHome(),
    const StatusScreen(),
    const ProfileScreen()
  ];
  List<Widget> icons = [
    const Icon(
      CupertinoIcons.chat_bubble_2_fill,
      size: 30,
    ),
    SizedBox(
      height: 30,
      width: 30,
      child: Image.asset(
        'images/status.png',
        color: Colors.white,
      ),
    ),
    const Icon(
      CupertinoIcons.person_fill,
      size: 30,
    )
  ];

  int index = 0;
  bool isLower = false;

  @override
  Widget build(BuildContext context) {
    String? wallpaper = context.watch<ChatLock>().wallpaper;
    final user = context.watch<AuthServices>().user;
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        setState(() {
          index = 0;
        });
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dx < 0) {
            if (index != 2) {
              setState(() {
                index++;
              });
            }
          } else if (details.velocity.pixelsPerSecond.dx > 0) {
            if (index != 0) {
              setState(() {
                index--;
              });
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  navigationKey.currentState!.setPage(2);
                },
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: CachedNetworkImage(
                        imageUrl: user.image,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Center(child: const CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                    StreamBuilder(
                      stream: AuthServices.listenToUser(),
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                          case ConnectionState.none:
                            return const CircleAvatar(
                              radius: 6,
                              backgroundColor: Colors.green,
                            );
                          case ConnectionState.active:
                          case ConnectionState.done:
                        }
                        final data = snapshot.data;
                        final updatedUser = User.fromJson(data!.data()!);
                        return updatedUser.isOnline
                            ? const CircleAvatar(
                                radius: 6,
                                backgroundColor: Colors.green,
                              )
                            : const SizedBox();
                      },
                    )
                  ],
                ),
              ),
            ),
            title: Text(
              user.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        PageTransition(
                            child: const SearchScreen(),
                            type: PageTransitionType.fade));
                  },
                  icon: const Icon(CupertinoIcons.search)),
              PopupMenuButton(
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      value: 'change PIN',
                      onTap: () {
                        changePIN(context);
                      },
                      child: const Text("Change PIN"),
                    ),
                    PopupMenuItem(
                      value: 'change wallpaper',
                      onTap: () async {
                        final picker = ImagePicker();
                        final image =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (image == null) return;
                        context.read<ChatLock>().setWallpaper(image);
                      },
                      child: Text(wallpaper == null || wallpaper == ""
                          ? "Set Wallpaper"
                          : "Change Wallpaper"),
                    ),
                    if (wallpaper != null && wallpaper != "")
                      PopupMenuItem(
                        value: 'delete wallpaper',
                        onTap: () {
                          context.read<ChatLock>().clearWallpaper();
                          setState(() {
                            wallpaper = null;
                          });
                          showSnackBar(
                              context: context,
                              content: 'Wallpaper deleted Successfully',
                              color: Colors.deepPurple);
                        },
                        child: const Text("Delete Wallpaper"),
                      ),
                  ];
                },
              )
            ],
          ),
          body: PageTransitionSwitcher(
            transitionBuilder: (child, primaryAnimation, secondaryAnimation) =>
                SharedAxisTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              child: child,
            ),
            child: screens[index],
          ),
          bottomNavigationBar: Theme(
              data: ThemeData(
                  iconTheme: const IconThemeData(color: Colors.white)),
              child: CurvedNavigationBar(
                key: navigationKey,
                items: icons,
                index: index,
                backgroundColor: Colors.transparent,
                height: 60,
                color: Colors.deepPurple,
                buttonBackgroundColor: Colors.deepPurple,
                onTap: (index) {
                  setState(() {
                    if (index < this.index) {
                      isLower = true;
                    } else {
                      isLower = false;
                    }
                    this.index = index;
                  });
                },
              )),
        ),
      ),
    );
  }
}
