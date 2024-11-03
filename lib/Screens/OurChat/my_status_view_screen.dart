import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:our_chat/Models/status_model.dart';
import 'package:our_chat/Services/auth_services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../Models/user_model.dart';
import '../../Constants/date_format.dart';
import '../../Widgets/OurChat/status_widget.dart';
import 'chatting_screen.dart';

class MyStatusViewScreen extends StatefulWidget {
  final User user;
  final int? initialIndex;

  const MyStatusViewScreen({super.key, required this.user, this.initialIndex,
  });

  @override
  State<MyStatusViewScreen> createState() => _MyStatusViewScreenState();
}

class _MyStatusViewScreenState extends State<MyStatusViewScreen> {
  late List<User> users = [];
  late List<User> viewedUsers = [];
  VideoPlayerController? videoPlayerController;
  late PageController controller = PageController();
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    _currentIndex = widget.initialIndex ?? 0;
    controller = PageController(initialPage: _currentIndex);
    _startTimer(status: widget.user.status[_currentIndex]);
    super.initState();
  }

  void _startTimer({required Status status}) async {
    final statuses = widget.user.status;
    int seconds = 7;
    if(status.type == 'video') {
      videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(status.url));
      await videoPlayerController!.initialize().then((value) {
        seconds = videoPlayerController!.value.duration.inSeconds + 1;
      },);
    }
    _timer = Timer.periodic(Duration(seconds: seconds), (timer) {
      if (_currentIndex < statuses.length - 1) {
        setState(() {
          _currentIndex++;
        });
        controller.animateToPage(_currentIndex,
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        timer.cancel();
        _startTimer(status: statuses[_currentIndex]);
      } else {
        timer.cancel(); // Stop when all statuses are viewed
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    if(videoPlayerController != null) {
      videoPlayerController!.dispose();
    }
    if(_timer != null) {
      _timer!.cancel();
    }
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthServices>().user;
    final mq = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: const Icon(CupertinoIcons.back, color: Colors.white,)),
        title: Row(
          children: [
            const SizedBox(
              width: 15,
            ),
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(widget.user.image),
            ),
            const SizedBox(
              width: 15,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16),
                ),
                Text(
                  DateFormat.getTimeAgo(widget.user.status[_currentIndex].time),
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                )
              ],
            )
          ],
        ),
      ),
      body: PageView.builder(
        itemCount: widget.user.status.length,
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final status = widget.user.status[index];
          return GestureDetector(
            onVerticalDragEnd: (details) {
              if(details.velocity.pixelsPerSecond.dy > 0) {
                Navigator.pop(context);
              } else {
                _timer!.cancel();
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return GestureDetector(
                        onTap: () {
                          FocusScopeNode currentFocus = FocusScope.of(context);
                          if (!currentFocus.hasPrimaryFocus) {
                            currentFocus.unfocus();
                          }
                        },
                        child: Container(
                          color: Colors.white,
                          padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom),
                          width: double.infinity,
                          child: StreamBuilder(
                              stream: FirebaseFirestore.instance.collection(AuthServices.usersCollection).doc(currentUser.id).snapshots(),
                              builder: (context, snapshot) {
                                if(!snapshot.hasData) {
                                  return const SizedBox();
                                }
                                final snap = snapshot.data;
                                final data = snap?.data(); // Cast to Map
                                final statusUser = User.fromJson(data!);

                                // Convert the status data to a list of Status objects
                                List<Status> statuses = statusUser.status;
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  context.read<AuthServices>().updateCurrentUserStatusCount(index: index, users: statuses[index].users);
                                });
                                viewedUsers = AuthServices.users.where((element) => statuses[index].users.contains(element.id),).toList();
                                return Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 10.0),
                                              child: Text(
                                                "Viewed by ",
                                                style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            Text(
                                              viewedUsers.length.toString(),
                                              style: const TextStyle(
                                                  fontSize: 20, color: Colors.black54),
                                            )
                                          ],
                                        ),
                                        IconButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _startTimer(status: status);
                                            },
                                            icon: const Icon(
                                              CupertinoIcons.xmark,
                                              color: Colors.black,
                                            ))
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    const Divider(
                                      color: Colors.black,
                                      thickness: 1,
                                    ),
                                    Expanded(
                                        child: ListView.builder(
                                            keyboardDismissBehavior:
                                            ScrollViewKeyboardDismissBehavior.onDrag,
                                            physics: const BouncingScrollPhysics(),
                                            itemCount: viewedUsers.length,
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Container(
                                                  decoration: const BoxDecoration(
                                                      shape: BoxShape.rectangle),
                                                  child: ListTile(
                                                    leading: CircleAvatar(
                                                      backgroundImage: NetworkImage(
                                                          viewedUsers[index].image),
                                                    ),
                                                    title: Text(
                                                      viewedUsers[index].name,
                                                      style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.black),
                                                    ),
                                                    subtitle: Text(
                                                      viewedUsers[index].email,
                                                      style: const TextStyle(
                                                          color: Colors.black54),
                                                    ),
                                                    trailing: IconButton(
                                                      onPressed: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (_) => ChattingScreen(
                                                                    chatUser:
                                                                    viewedUsers[index],
                                                                    user: currentUser)));
                                                      },
                                                      icon: const Icon(
                                                          CupertinoIcons.chat_bubble),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            })),
                                  ],
                                );
                              }
                          ),
                        ),
                      );
                    });
              }
            },
            child: Stack(
              children: [
                StatusWidget(user: widget.user, status: status),
                if(status.caption != null && status.caption!.isNotEmpty)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    alignment: Alignment.topCenter,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                    height: mq.height*.15,
                    width: mq.width,
                    color: Colors.black38,
                    child: Text(status.caption!, style: const TextStyle(color: Colors.white),),
                  ),
                ),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: (){
                      if(_currentIndex > 0) {
                        setState(() {
                          _currentIndex--;
                        });
                        controller.animateToPage(_currentIndex,
                            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        _timer!.cancel();
                        _startTimer(status: widget.user.status[_currentIndex]);
                      }
                    },
                    child: Container(
                      height: mq.height,
                      color: Colors.transparent,
                    ),
                  )),
                  Expanded(child: GestureDetector(
                    onTap: (){
                      if(_currentIndex < widget.user.status.length - 1) {
                        setState(() {
                          _currentIndex++;
                        });
                        controller.animateToPage(_currentIndex,
                            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        _timer!.cancel();
                        _startTimer(status: widget.user.status[_currentIndex]);
                      } else {
                        _timer!.cancel();
                        Navigator.pop(context);
                        _timer = null;
                      }
                    },
                    child: Container(
                      height: mq.height,
                      color: Colors.transparent,
                    ),
                  ))
                ]),
              ],
            ),
          );
        },
      ),
    );
    // final List<StoryItem> storyItems = [];
    // for (int i = 0; i < widget.user.status.length; i++) {
    //   if (widget.user.status[i].type == 'image') {
    //     storyItems.add(StoryItem.inlineImage(
    //         url: widget.user.status[i].url, controller: controller));
    //   } else {
    //     storyItems.add(StoryItem.pageVideo(widget.user.status[i].url,
    //         controller: controller));
    //   }
    // }
    // return StoryView(
    //   storyItems: storyItems,
    //   controller: controller,
    //   inline: false,
    //   repeat: false,
    //   onComplete: () => Navigator.pop(context),
    //   onVerticalSwipeComplete: (verticalSwipeDirection) {
    //     controller.pause();
    //     showModalBottomSheet(
    //         context: context,
    //         builder: (BuildContext context) {
    //           return GestureDetector(
    //             onTap: () {
    //               FocusScopeNode currentFocus = FocusScope.of(context);
    //               if (!currentFocus.hasPrimaryFocus) {
    //                 currentFocus.unfocus();
    //               }
    //             },
    //             child: Container(
    //               color: Colors.white,
    //               padding: EdgeInsets.only(
    //                   bottom: MediaQuery.of(context).viewInsets.bottom),
    //               width: double.infinity,
    //               child: StreamBuilder(
    //                 stream: FirebaseFirestore.instance.collection(AuthServices.usersCollection).doc(currentUser.id).snapshots(),
    //                 builder: (context, snapshot) {
    //                   final snap = snapshot.data;
    //                   final data = snap?.data(); // Cast to Map
    //                   final statusList = data?['status'] as List<dynamic>? ?? []; // Safely access 'status' field
    //
    //                   // Convert the status data to a list of Status objects
    //                   List<Status> statuses = statusList.map((e) => Status.fromJson(e)).toList();
    //                   viewedUsers = AuthServices.users.where((element) => statuses[0].users.contains(element.id),).toList();
    //                   return Column(
    //                     children: [
    //                       Row(
    //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                         children: [
    //                           Row(
    //                             crossAxisAlignment: CrossAxisAlignment.center,
    //                             children: [
    //                               const Padding(
    //                                 padding: EdgeInsets.symmetric(horizontal: 10.0),
    //                                 child: Text(
    //                                   "Viewed by ",
    //                                   style: TextStyle(
    //                                       fontSize: 24,
    //                                       fontWeight: FontWeight.bold),
    //                                 ),
    //                               ),
    //                               Text(
    //                                 viewedUsers.length.toString(),
    //                                 style: const TextStyle(
    //                                     fontSize: 20, color: Colors.black54),
    //                               )
    //                             ],
    //                           ),
    //                           IconButton(
    //                               onPressed: () {
    //                                 Navigator.pop(context);
    //                               },
    //                               icon: const Icon(
    //                                 CupertinoIcons.xmark,
    //                                 color: Colors.black,
    //                               ))
    //                         ],
    //                       ),
    //                       const SizedBox(
    //                         height: 10,
    //                       ),
    //                       const Divider(
    //                         color: Colors.black,
    //                         thickness: 1,
    //                       ),
    //                       Expanded(
    //                           child: ListView.builder(
    //                               keyboardDismissBehavior:
    //                                   ScrollViewKeyboardDismissBehavior.onDrag,
    //                               physics: const BouncingScrollPhysics(),
    //                               itemCount: viewedUsers.length,
    //                               itemBuilder: (context, index) {
    //                                 return Padding(
    //                                   padding: const EdgeInsets.all(8.0),
    //                                   child: Flexible(
    //                                     child: Container(
    //                                       decoration: const BoxDecoration(
    //                                           shape: BoxShape.rectangle),
    //                                       child: ListTile(
    //                                         leading: CircleAvatar(
    //                                           backgroundImage: NetworkImage(
    //                                               viewedUsers[index].image),
    //                                         ),
    //                                         title: Text(
    //                                           viewedUsers[index].name,
    //                                           style: const TextStyle(
    //                                               fontSize: 18,
    //                                               fontWeight: FontWeight.bold,
    //                                               color: Colors.black),
    //                                         ),
    //                                         subtitle: Text(
    //                                           viewedUsers[index].email,
    //                                           style: const TextStyle(
    //                                               color: Colors.black54),
    //                                         ),
    //                                         trailing: IconButton(
    //                                           onPressed: () {
    //                                             Navigator.push(
    //                                                 context,
    //                                                 MaterialPageRoute(
    //                                                     builder: (_) => ChattingScreen(
    //                                                         chatUser:
    //                                                             viewedUsers[index],
    //                                                         user: currentUser)));
    //                                           },
    //                                           icon: const Icon(
    //                                               CupertinoIcons.chat_bubble),
    //                                         ),
    //                                       ),
    //                                     ),
    //                                   ),
    //                                 );
    //                               })),
    //                     ],
    //                   );
    //                 }
    //               ),
    //             ),
    //           );
    //         });
    //   },
    // );
  }
}
