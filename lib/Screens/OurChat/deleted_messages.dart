import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:our_chat/Constants/alerts.dart';
import 'package:our_chat/Screens/OurChat/user_details.dart';
import 'package:our_chat/Services/auth_services.dart';
import 'package:our_chat/Services/message_services.dart';
import 'package:our_chat/Widgets/open_item.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../Models/message_model.dart';
import '../../../Models/user_model.dart';
import '../../Constants/date_format.dart';
import '../../Services/chat_lock.dart';
import '../../Widgets/OurChat/chat_bubble.dart';
import '../image_viewer.dart';
import 'package:http/http.dart' as http;

class DeletedMessages extends StatefulWidget {
  final User user;
  final User chatUser;

  const DeletedMessages({
    super.key,
    required this.user,
    required this.chatUser,
  });

  @override
  State<DeletedMessages> createState() => _DeletedMessagesState();
}

class _DeletedMessagesState extends State<DeletedMessages> {
  List<Message> deletedMessages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    ChatLock.getWallpaper();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDeletedMessages() {
    return MessageServices.firestore
        .collection(
        '${MessageServices.messagesCollection}/${MessageServices.getConversationId(widget.chatUser.id)}/messages/')
        .where('type', isEqualTo: 'deleted')
        .snapshots();
  }

  Future<void> saveFileFromUrl(Message message, String fileName) async {
    try {
      // Fetch the file
      final response = await http.get(Uri.parse(message.text));

      if (response.statusCode == 200) {
        // Get the external storage directory
        Directory? externalDir = message.type == 'video'
            ? Directory('/storage/emulated/0/Download/Notepad/Videos')
            : Directory('/storage/emulated/0/Download/Notepad/Images');
        if (!await externalDir.exists()) {
          await externalDir.create(recursive: true);
        }
        String filePath = '';
        filePath = '${externalDir.path}/$fileName';
        // if(Platform.isAndroid) {
        //   filePath = '/storage/emulated/0/Download/Notepad/$fileName';
        // }
        // else{
        //   filePath = '${externalDir!.path}/$fileName';
        // }

        // Save the file
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Notify the media scanner to add the file to the gallery
        Process.run('am', [
          'broadcast',
          '-a',
          'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
          '-d',
          'file://$filePath'
        ]);

        showSnackBar(
            context: context,
            content: 'File saved to gallery',
            color: Colors.deepPurple);
        // showAlert(context: context, title: 'File saved', content: 'file saved to $filePath');
      } else {
        showAlert(
            context: context,
            title: 'Failed to fetch',
            content: 'Failed to fetch file: ${response.statusCode}');
      }
    } catch (e) {
      showAlert(
          context: context,
          title: "Error saving",
          content: 'Error saving file $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String? wallpaper = context.watch<ChatLock>().wallpaper;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: wallpaper == null || wallpaper == ""
              ? Colors.white
              : Colors.transparent,
          image: wallpaper == null || wallpaper == ""
              ? null
              : DecorationImage(
              image: FileImage(File(wallpaper)), fit: BoxFit.cover),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: StreamBuilder(
              stream: AuthServices.getUserInfo(widget.chatUser),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text("Error");
                }
                if (!snapshot.hasData) {
                  InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          PageTransition(
                              child: UserDetails(
                                chatUser: widget.chatUser,
                              ),
                              type: PageTransitionType.topToBottom));
                    },
                    child: Row(
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(right: 18.0),
                            child: OpenItem(
                                openChild: ImageViewer(
                                  title: widget.chatUser.name,
                                  image: widget.chatUser.image,
                                ),
                                closedChild: SizedBox(
                                  height: 40,
                                  width: 40,
                                  child: ClipOval(
                                      child: CachedNetworkImage(
                                        fit: BoxFit.cover,
                                        imageUrl: widget.chatUser.image,
                                        placeholder: (context, url) => const Center(
                                            child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                      )),
                                ))),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.chatUser.name,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              widget.chatUser.isOnline
                                  ? const Text(
                                'Online',
                                style: TextStyle(fontSize: 14),
                              )
                                  : Text(
                                  overflow: TextOverflow.fade,
                                  DateFormat.getLastActiveTime(
                                      context: context,
                                      lastActive:
                                      widget.chatUser.lastActive),
                                  style: const TextStyle(fontSize: 14))
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final data = snapshot.data?.docs;
                final list =
                    data?.map((e) => User.fromJson(e.data())).toList() ?? [];
                final updatedUser = list.isNotEmpty ? list[0] : widget.chatUser;
                return InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        PageTransition(
                            child: UserDetails(
                              chatUser: updatedUser,
                            ),
                            type: PageTransitionType.topToBottom));
                  },
                  child: Row(
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(right: 18.0),
                          child: OpenItem(
                              openChild: ImageViewer(
                                title: updatedUser.name,
                                image: updatedUser.image,
                              ),
                              closedChild: SizedBox(
                                height: 40,
                                width: 40,
                                child: ClipOval(
                                    child: CachedNetworkImage(
                                      fit: BoxFit.cover,
                                      imageUrl: updatedUser.image,
                                      placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.error),
                                    )),
                              ))),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              updatedUser.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            updatedUser.isOnline
                                ? const Text(
                              'Online',
                              style: TextStyle(fontSize: 14),
                            )
                                : Text(
                                overflow: TextOverflow.fade,
                                DateFormat.getLastActiveTime(
                                    context: context,
                                    lastActive: updatedUser.lastActive),
                                style: const TextStyle(fontSize: 14))
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              PopupMenuButton(itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                    value: 'refresh',
                    onTap: () {
                      setState(() {});
                    },
                    child: const Text("Refresh Chat"),
                  ),
                  if (deletedMessages.isNotEmpty)
                    PopupMenuItem(
                      value: 'jump to first',
                      onTap: () {
                        _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: 300.ms,
                            curve: Curves.easeInOut);
                      },
                      child: const Text("Jump to First Message"),
                    ),
                  if (deletedMessages.isNotEmpty)
                    PopupMenuItem(
                      value: 'jump to last',
                      onTap: () {
                        _scrollController.animateTo(
                            _scrollController.position.minScrollExtent,
                            duration: 300.ms,
                            curve: Curves.easeInOut);
                      },
                      child: const Text("Jump to Last Message"),
                    ),
                  if (deletedMessages.isNotEmpty &&
                      AuthServices.currentUser.email ==
                          'alanashu07@gmail.com')
                    PopupMenuItem(
                        value: 'delete',
                        onTap: () async {
                          for (var message in deletedMessages) {
                            await MessageServices.firestore
                                .collection(
                                '${MessageServices.messagesCollection}/${MessageServices.getConversationId(widget.chatUser.id)}/messages/')
                                .doc(message.id)
                                .delete();
                          }
                        },
                        child: const Text("Delete deleted Messages"))
                ];
              })
            ],
          ),
          body: Column(
            children: [
              Expanded(
                  child: StreamBuilder(
                    stream:
                    getDeletedMessages(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text(snapshot.error.toString()));
                      }
                      final data = snapshot.data?.docs;
                      deletedMessages =
                          data?.map((e) => Message.fromJson(e.data())).toList() ??
                              [];
                      return deletedMessages.isEmpty
                          ? const Center(
                        child: Text(
                          "Say Hello! 👋",
                          style: TextStyle(fontSize: 24),
                        ),
                      )
                          : ListView.builder(
                          controller: _scrollController,
                          shrinkWrap: true,
                          reverse: true,
                          itemCount: deletedMessages.length,
                          itemBuilder: (context, index) {
                            DateTime? previousMessageDate;
                            DateTime? thisMessageDate;
                            thisMessageDate =
                                DateTime.fromMillisecondsSinceEpoch(
                                    int.parse(deletedMessages[index].sentAt));
                            if (index != deletedMessages.length - 1) {
                              previousMessageDate =
                                  DateTime.fromMillisecondsSinceEpoch(
                                      int.parse(deletedMessages[index + 1].sentAt));
                            }
                            if ((previousMessageDate != null &&
                                previousMessageDate.day !=
                                    thisMessageDate.day) ||
                                index == deletedMessages.length - 1) {
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(18.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade900,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        DateFormat.getMessageDay(
                                            context: context,
                                            date: deletedMessages[index].sentAt),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                      highlightColor: deletedMessages[index].sender ==
                                          widget.user.id
                                          ? Colors.deepPurple.shade200
                                          : Colors.blue.shade200,
                                      splashColor: deletedMessages[index].sender ==
                                          widget.user.id
                                          ? Colors.deepPurple.shade100
                                          : Colors.blue.shade100,
                                      onLongPress: () {
                                        deletedMessages[index].type != 'text'
                                            ? showMediaOptions(deletedMessages[index])
                                            : showOptions(deletedMessages[index]);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: ChatBubble(
                                          chatUser: widget.chatUser,
                                          message: deletedMessages[index],
                                        ),
                                      ))
                                ],
                              );
                            }
                            return InkWell(
                                highlightColor:
                                deletedMessages[index].sender == widget.user.id
                                    ? Colors.deepPurple.shade200
                                    : Colors.blue.shade200,
                                splashColor:
                                deletedMessages[index].sender == widget.user.id
                                    ? Colors.deepPurple.shade100
                                    : Colors.blue.shade100,
                                onLongPress: () {
                                  deletedMessages[index].type != 'text'
                                      ? showMediaOptions(deletedMessages[index])
                                      : showOptions(deletedMessages[index]);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: ChatBubble(
                                    chatUser: widget.chatUser,
                                    message: deletedMessages[index],
                                  ),
                                ));
                          });
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Future<XFile> convertUint8ListToXFile(Uint8List uint8List) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/temp_image.png';

    // Write the Uint8List data to a temporary file
    await File(tempPath).writeAsBytes(uint8List);

    return XFile(tempPath);
  }

  Future showOptions(Message message) {
    final mq = MediaQuery.of(context).size;
    return showModalBottomSheet(
        context: context,
        builder: (_) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            height: mq.height * .48,
            child: ListView(
              children: [
                InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: message.text))
                        .then((value) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Message Copied to clipboard"),
                      ));
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      height: mq.height * .05,
                      child: const Row(
                        children: [
                          Icon(Icons.copy_all),
                          SizedBox(
                            width: 20,
                          ),
                          Text(
                            "Copy Text",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(),
                if (message.sender == widget.user.id)
                  InkWell(
                    onTap: () {
                      MessageServices.firestore
                          .collection(
                          '${MessageServices.messagesCollection}/${MessageServices.getConversationId(widget.chatUser.id)}/messages/')
                          .doc(message.id)
                          .delete();
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        height: mq.height * .05,
                        child: const Row(
                          children: [
                            Icon(CupertinoIcons.delete),
                            SizedBox(
                              width: 20,
                            ),
                            Text(
                              "Delete Message",
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                if (message.sender == widget.user.id) const Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    height: mq.height * .05,
                    child: Row(
                      children: [
                        const Icon(Icons.done_all),
                        const SizedBox(
                          width: 20,
                        ),
                        Text(
                          "Sent At: ${DateFormat.getMessageTime(context: context, time: message.sentAt)}",
                        )
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    height: mq.height * .05,
                    child: Row(
                      children: [
                        const Icon(Icons.remove_red_eye_outlined),
                        const SizedBox(
                          width: 20,
                        ),
                        message.readAt.isEmpty
                            ? const Text(
                          "Not read yet!",
                        )
                            : Text(
                          "Read At: ${DateFormat.getMessageTime(context: context, time: message.readAt)}",
                        )
                      ],
                    ),
                  ),
                ),
                const Divider(),
              ],
            ),
          );
        });
  }

  Future showMediaOptions(Message message) {
    final mq = MediaQuery.of(context).size;
    return showModalBottomSheet(
        context: context,
        builder: (_) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            height: mq.height * .48,
            child: ListView(
              children: [
                InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: message.text))
                        .then((value) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Link Copied to clipboard"),
                      ));
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      height: mq.height * .05,
                      child: const Row(
                        children: [
                          Icon(Icons.copy_all),
                          SizedBox(
                            width: 20,
                          ),
                          Text(
                            "Copy Link",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(),
                InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    await saveFileFromUrl(
                        message,
                        message.type == 'video'
                            ? 'Video-${message.id}.mp4'
                            : 'Image-${message.id}.jpg');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      height: mq.height * .05,
                      child: const Row(
                        children: [
                          Icon(Icons.download),
                          SizedBox(
                            width: 20,
                          ),
                          Text(
                            "Download Media",
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    height: mq.height * .05,
                    child: Row(
                      children: [
                        const Icon(Icons.done_all),
                        const SizedBox(
                          width: 20,
                        ),
                        Text(
                          "Sent At: ${DateFormat.getMessageTime(context: context, time: message.sentAt)}",
                        )
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    height: mq.height * .05,
                    child: Row(
                      children: [
                        const Icon(Icons.remove_red_eye_outlined),
                        const SizedBox(
                          width: 20,
                        ),
                        message.readAt.isEmpty
                            ? const Text(
                          "Not read yet!",
                        )
                            : Text(
                          "Read At: ${DateFormat.getMessageTime(context: context, time: message.readAt)}",
                        )
                      ],
                    ),
                  ),
                ),
                const Divider(),
              ],
            ),
          );
        });
  }
}
