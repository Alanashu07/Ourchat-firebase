import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:our_chat/Widgets/OurChat/status_widget.dart';
import 'package:video_player/video_player.dart';
import '../../../Models/user_model.dart';
import '../../Constants/date_format.dart';
import '../../Models/message_model.dart';
import '../../Models/status_model.dart';
import '../../Services/auth_services.dart';
import '../../Services/message_services.dart';

class StatusViewScreen extends StatefulWidget {
  final User user;

  const StatusViewScreen({super.key, required this.user});

  @override
  State<StatusViewScreen> createState() => _StatusViewScreenState();
}

class _StatusViewScreenState extends State<StatusViewScreen> {
  TextEditingController messageController = TextEditingController();
  VideoPlayerController? videoPlayerController;
  final _controller = PageController();
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    _startTimer(status: widget.user.status[0]);
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
        _controller.animateToPage(_currentIndex,
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        timer.cancel();
        _startTimer(status: widget.user.status[_currentIndex]);
      } else {
        timer.cancel(); // Stop when all statuses are viewed
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    if(videoPlayerController != null) {
      videoPlayerController!.dispose();
    }
   if(_timer != null) {
     _timer!.cancel();
   }
   _timer = null;
    super.dispose();
  }



  double watchSeconds = 0.0;

  @override
  Widget build(BuildContext context) {
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
            SizedBox(
              height: 40,
              width: 40,
              child: ClipOval(
                  child: CachedNetworkImage(
                    fit: BoxFit.cover,
                    imageUrl: widget.user.image,
                    placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  )),
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
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final status = widget.user.status[index];
          AuthServices.viewStatus(user: widget.user, status: status);
          return GestureDetector(
            onVerticalDragEnd: (details) {
              if(details.velocity.pixelsPerSecond.dy > 0) {
                Navigator.pop(context);
              } else {
                _timer!.cancel();
                showModalBottomSheet(
                    backgroundColor: Colors.transparent,
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
                          height: mq.height,
                          color: Colors.black12,
                          padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom),
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Card(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15)),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        SizedBox(
                                          width: mq.width * .04,
                                        ),
                                        Expanded(
                                            child: TextFormField(
                                              autofocus: true,
                                              textCapitalization:
                                              TextCapitalization.sentences,
                                              keyboardType: TextInputType.multiline,
                                              minLines: 1,
                                              maxLines: 5,
                                              controller: messageController,
                                              decoration: const InputDecoration(
                                                  hintText: "Type here...",
                                                  hintStyle:
                                                  TextStyle(color: Colors.deepPurple),
                                                  border: InputBorder.none),
                                            )),
                                        SizedBox(
                                          width: mq.width * .02,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 3.0),
                                  child: MaterialButton(
                                    onPressed: () {
                                      if (messageController.text.trim().isNotEmpty) {
                                        Message message = Message(
                                            id: DateFormat.getNow(),
                                            sender: AuthServices.currentUser.id,
                                            receiver: widget.user.id,
                                            tagType: status.type == 'image' ? 'statusImage' : 'statusVideo',
                                            taggedMessage: status.id,
                                            isTagged: true,
                                            text: messageController.text.trim(),
                                            sentAt: DateFormat.getNow(),
                                            readAt: '',
                                            type: 'text');
                                        MessageServices.sendMessage(
                                            widget.user, message);
                                        messageController.clear();
                                        Navigator.pop(context);
                                      }
                                    },
                                    shape: const CircleBorder(),
                                    minWidth: 25,
                                    color: Colors.deepPurple,
                                    height: 40,
                                    child: const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              ],
                            ),
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
                        _controller.animateToPage(_currentIndex,
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
                        _controller.animateToPage(_currentIndex,
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
    // return StoryView(
    //   storyItems: storyItems,
    //   controller: _controller,
    //   inline: false,
    //   repeat: false,
    //   onComplete: () => Navigator.pop(context),
    //   onVerticalSwipeComplete: (verticalSwipeDirection) {
    //     _controller.pause();
    //     showModalBottomSheet(
    //         backgroundColor: Colors.transparent,
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
    //               height: mq.height,
    //               color: Colors.black12,
    //               padding: EdgeInsets.only(
    //                   bottom: MediaQuery.of(context).viewInsets.bottom),
    //               width: double.infinity,
    //               child: Padding(
    //                 padding: const EdgeInsets.all(8.0),
    //                 child: Row(
    //                   crossAxisAlignment: CrossAxisAlignment.end,
    //                   children: [
    //                     Expanded(
    //                       child: Card(
    //                         color: Colors.white,
    //                         shape: RoundedRectangleBorder(
    //                             borderRadius: BorderRadius.circular(15)),
    //                         child: Row(
    //                           crossAxisAlignment: CrossAxisAlignment.end,
    //                           children: [
    //                             SizedBox(
    //                               width: mq.width * .04,
    //                             ),
    //                             Expanded(
    //                                 child: TextFormField(
    //                               autofocus: true,
    //                               textCapitalization:
    //                                   TextCapitalization.sentences,
    //                               keyboardType: TextInputType.multiline,
    //                               minLines: 1,
    //                               maxLines: 5,
    //                               controller: messageController,
    //                               decoration: const InputDecoration(
    //                                   hintText: "Type here...",
    //                                   hintStyle:
    //                                       TextStyle(color: Colors.deepPurple),
    //                                   border: InputBorder.none),
    //                             )),
    //                             SizedBox(
    //                               width: mq.width * .02,
    //                             )
    //                           ],
    //                         ),
    //                       ),
    //                     ),
    //                     Padding(
    //                       padding: const EdgeInsets.only(bottom: 3.0),
    //                       child: MaterialButton(
    //                         onPressed: () {
    //                           if (messageController.text.trim().isNotEmpty) {
    //                             Message message = Message(
    //                                 id: DateFormat.getNow(),
    //                                 sender: AuthServices.currentUser.id,
    //                                 receiver: widget.user.id,
    //                                 text: messageController.text.trim(),
    //                                 sentAt: DateFormat.getNow(),
    //                                 readAt: '',
    //                                 type: 'text');
    //                             MessageServices.sendMessage(
    //                                 widget.user, message);
    //                             messageController.clear();
    //                           }
    //                         },
    //                         shape: const CircleBorder(),
    //                         minWidth: 25,
    //                         color: Colors.deepPurple,
    //                         height: 40,
    //                         child: const Icon(
    //                           Icons.send,
    //                           color: Colors.white,
    //                         ),
    //                       ),
    //                     )
    //                   ],
    //                 ),
    //               ),
    //             ),
    //           );
    //         });
    //   },
    // );
  }
}
