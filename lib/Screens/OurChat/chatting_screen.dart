import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:our_chat/Constants/alerts.dart';
import 'package:our_chat/Screens/OurChat/deleted_messages.dart';
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
import 'package:permission_handler/permission_handler.dart';

class ChattingScreen extends StatefulWidget {
  final User user;
  final User chatUser;

  const ChattingScreen({
    super.key,
    required this.user,
    required this.chatUser,
  });

  @override
  State<ChattingScreen> createState() => _ChattingScreenState();
}

class _ChattingScreenState extends State<ChattingScreen> {
  List<Message> messages = [];
  List<Message> deletedMessages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  int limit = 100;
  bool sending = false;
  FocusNode focus = FocusNode();
  bool isTagged = false;
  Message? taggedMessage;
  String tagType = 'message';

  @override
  void initState() {
    super.initState();
    ChatLock.getWallpaper();
    uploadMessages();
  }

  Future<void> getDeletedMessages() async {
    final snap = await MessageServices.firestore
        .collection(
            '${MessageServices.messagesCollection}/${MessageServices.getConversationId(widget.chatUser.id)}/messages/')
        .where('type', isEqualTo: 'deleted')
        .get();
    final data = snap.docs;
    deletedMessages = data.map((e) => Message.fromJson(e.data())).toList();
  }

  uploadMessages() async {
    final snap = await MessageServices.firestore
        .collection(
            '${MessageServices.messagesCollection}/${MessageServices.getConversationId(widget.chatUser.id)}/messages/')
        .where('isUploaded', isEqualTo: false)
        .get();
    final data = snap.docs;
    List<Message> list = data.map((e) => Message.fromJson(e.data())).toList();
    for (Message message in list) {
      await MessageServices.firestore
          .collection(
              '${MessageServices.messagesCollection}/${MessageServices.getConversationId(widget.chatUser.id)}/messages/')
          .doc(message.id)
          .update({'isUploaded': true});
    }
    setState(() {});
  }

  Future<void> saveFileFromUrl(Message message, String fileName) async {
    try {
      // Fetch the file
      final response = await http.get(Uri.parse(message.text));

      if (response.statusCode == 200) {
        // Get the external storage directory
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
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
              FutureBuilder(
                  future: getDeletedMessages(),
                  builder: (context, snapshot) {
                    return PopupMenuButton(itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem(
                          value: 'refresh',
                          onTap: () {
                            setState(() {});
                          },
                          child: const Text("Refresh Chat"),
                        ),
                        if (messages.isNotEmpty)
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
                        if (messages.isNotEmpty)
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
                        if ((messages.length + deletedMessages.length) >= limit)
                          PopupMenuItem(
                            value: 'load more',
                            onTap: () {
                              setState(() {
                                limit += 100;
                              });
                            },
                            child: const Text("Load More Messages"),
                          ),
                        if (deletedMessages.isNotEmpty &&
                            AuthServices.currentUser.email ==
                                'alanashu07@gmail.com')
                          PopupMenuItem(
                            child: const Text('Show deleted Messages'),
                            value: 'show deleted',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  PageTransition(
                                      child: DeletedMessages(
                                          user: widget.user,
                                          chatUser: widget.chatUser),
                                      type: PageTransitionType.bottomToTop));
                            },
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
                                getDeletedMessages();
                              },
                              child: const Text("Delete deleted Messages"))
                      ];
                    });
                  })
            ],
          ),
          body: Column(
            children: [
              Expanded(
                  child: StreamBuilder(
                stream:
                    MessageServices.getLimitedMessages(widget.chatUser, limit),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  }
                  final data = snapshot.data?.docs;
                  messages =
                      data?.map((e) => Message.fromJson(e.data())).toList() ??
                          [];
                  messages = messages
                      .where(
                        (element) => element.type != 'deleted',
                      )
                      .toList();
                  return messages.isEmpty
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
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            DateTime? previousMessageDate;
                            DateTime? thisMessageDate;
                            Message? tagMsg;
                            if (messages[index].taggedMessage != null &&
                                messages[index].tagType == 'message') {
                              final list = messages
                                  .where((element) =>
                                      element.id ==
                                      messages[index].taggedMessage)
                                  .toList();
                              if (list.isNotEmpty) {
                                tagMsg = list[0];
                              }
                            }
                            thisMessageDate =
                                DateTime.fromMillisecondsSinceEpoch(
                                    int.parse(messages[index].sentAt));
                            if (index != messages.length - 1) {
                              previousMessageDate =
                                  DateTime.fromMillisecondsSinceEpoch(
                                      int.parse(messages[index + 1].sentAt));
                            }
                            if ((previousMessageDate != null &&
                                    previousMessageDate.day !=
                                        thisMessageDate.day) ||
                                index == messages.length - 1) {
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
                                            date: messages[index].sentAt),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                      highlightColor: messages[index].sender ==
                                              widget.user.id
                                          ? Colors.deepPurple.shade200
                                          : Colors.blue.shade200,
                                      splashColor: messages[index].sender ==
                                              widget.user.id
                                          ? Colors.deepPurple.shade100
                                          : Colors.blue.shade100,
                                      onLongPress: () {
                                        messages[index].type != 'text'
                                            ? showMediaOptions(messages[index])
                                            : showOptions(messages[index]);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Slidable(
                                          startActionPane: ActionPane(
                                              extentRatio: 0.25,
                                              motion: StretchMotion(),
                                              children: [
                                                SlidableAction(
                                                  onPressed: (context) {
                                                    setState(() {
                                                      isTagged = true;
                                                      taggedMessage =
                                                          messages[index];
                                                    });
                                                    focus.requestFocus();
                                                  },
                                                  backgroundColor:
                                                      Colors.blueGrey,
                                                  foregroundColor: Colors.white,
                                                  icon: Icons.reply,
                                                  label: 'Reply',
                                                )
                                              ]),
                                          endActionPane: ActionPane(
                                              motion: BehindMotion(),
                                              children: [
                                                SlidableAction(
                                                  onPressed: (context) {
                                                    setState(() {
                                                      isTagged = true;
                                                      taggedMessage =
                                                          messages[index];
                                                    });
                                                    focus.requestFocus();
                                                  },
                                                  backgroundColor:
                                                      Colors.blueGrey,
                                                  foregroundColor: Colors.white,
                                                  icon: Icons.reply,
                                                  label: 'Reply',
                                                ),
                                                if (messages[index].sender ==
                                                    widget.user.id)
                                                  SlidableAction(
                                                    onPressed: (context) {
                                                      MessageServices.firestore
                                                          .collection(
                                                              '${MessageServices.messagesCollection}/${MessageServices.getConversationId(widget.chatUser.id)}/messages/')
                                                          .doc(messages[index]
                                                              .id)
                                                          .update({
                                                        'type': 'deleted'
                                                      });
                                                    },
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                    foregroundColor:
                                                        Colors.white,
                                                    icon: CupertinoIcons.delete,
                                                    label: 'Delete',
                                                  )
                                              ]),
                                          child: ChatBubble(
                                            taggedMessage: tagMsg,
                                            chatUser: widget.chatUser,
                                            message: messages[index],
                                          ),
                                        ),
                                      ))
                                ],
                              );
                            }
                            return InkWell(
                                highlightColor:
                                    messages[index].sender == widget.user.id
                                        ? Colors.deepPurple.shade200
                                        : Colors.blue.shade200,
                                splashColor:
                                    messages[index].sender == widget.user.id
                                        ? Colors.deepPurple.shade100
                                        : Colors.blue.shade100,
                                onLongPress: () {
                                  messages[index].type != 'text'
                                      ? showMediaOptions(messages[index])
                                      : showOptions(messages[index]);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Slidable(
                                    startActionPane: ActionPane(
                                        extentRatio: 0.25,
                                        motion: StretchMotion(),
                                        children: [
                                          SlidableAction(
                                            onPressed: (context) {
                                              setState(() {
                                                isTagged = true;
                                                taggedMessage = messages[index];
                                              });
                                              focus.requestFocus();
                                            },
                                            backgroundColor: Colors.blueGrey,
                                            foregroundColor: Colors.white,
                                            icon: Icons.reply,
                                            label: 'Reply',
                                          )
                                        ]),
                                    endActionPane: ActionPane(
                                        motion: BehindMotion(),
                                        children: [
                                          SlidableAction(
                                            onPressed: (context) {
                                              setState(() {
                                                isTagged = true;
                                                taggedMessage = messages[index];
                                              });
                                              focus.requestFocus();
                                            },
                                            backgroundColor: Colors.blueGrey,
                                            foregroundColor: Colors.white,
                                            icon: Icons.reply,
                                            label: 'Reply',
                                          ),
                                          if (messages[index].sender ==
                                              widget.user.id)
                                            SlidableAction(
                                              onPressed: (context) {
                                                MessageServices.firestore
                                                    .collection(
                                                        '${MessageServices.messagesCollection}/${MessageServices.getConversationId(widget.chatUser.id)}/messages/')
                                                    .doc(messages[index].id)
                                                    .update(
                                                        {'type': 'deleted'});
                                              },
                                              backgroundColor: Colors.redAccent,
                                              foregroundColor: Colors.white,
                                              icon: CupertinoIcons.delete,
                                              label: 'Delete',
                                            )
                                        ]),
                                    child: ChatBubble(
                                      taggedMessage: tagMsg,
                                      chatUser: widget.chatUser,
                                      message: messages[index],
                                    ),
                                  ),
                                ));
                          });
                },
              )),
              if (sending)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 20),
                    child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.deepPurple),
                            color: Colors.deepPurple.shade100),
                        child: CircularProgressIndicator(
                            color: Colors.blueGrey[900])),
                  ),
                ),
              _chatInput(),
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

  Widget _chatInput() {
    final mq = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  children: [
                    if (isTagged && taggedMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Container(
                          height: taggedMessage!.type == 'text' ? 100 : 120,
                          padding: EdgeInsets.all(8),
                          width: mq.width,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    taggedMessage!.sender ==
                                            AuthServices.currentUser.id
                                        ? 'You'
                                        : widget.chatUser.name,
                                    style: TextStyle(
                                        color: taggedMessage!.sender ==
                                                AuthServices.currentUser.id
                                            ? Colors.deepPurple
                                            : Colors.lightBlue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                      onPressed: () {
                                        setState(() {
                                          taggedMessage = null;
                                          isTagged = false;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.close,
                                        size: 15,
                                      ))
                                ],
                              ),
                              taggedMessage!.type == 'image' ||
                                      taggedMessage!.type == 'gif'
                                  ? SizedBox(
                                      height: 50,
                                      width: 50,
                                      child: Image.network(
                                        taggedMessage!.text,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : taggedMessage!.type == 'video'
                                      ? Text(
                                          "Tagged a video",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : Text(
                                          taggedMessage!.text,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                            ],
                          ),
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                            child: TextFormField(
                          focusNode: focus,
                          contentInsertionConfiguration:
                              ContentInsertionConfiguration(
                            onContentInserted: (value) async {
                              final content = value.data;
                              if (content is Uint8List) {
                                convertUint8ListToXFile(content)
                                    .then((xFile) async {
                                  sendMedia(xFile, 'image');
                                });
                              } else {
                                // Handle other types of content
                                setState(() {
                                  _messageController.text = content.toString();
                                });
                              }
                            },
                            allowedMimeTypes: [
                              'image/png',
                              'image/jpeg',
                              'image/gif'
                            ],
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          minLines: 1,
                          maxLines: 5,
                          controller: _messageController,
                          decoration: const InputDecoration(
                              hintText: "Type here...",
                              hintStyle: TextStyle(color: Colors.deepPurple),
                              border: InputBorder.none),
                        )),
                        IconButton(
                            onPressed: _imageSelection,
                            icon: const Icon(
                              size: 26,
                              Icons.image,
                              color: Colors.deepPurple,
                            )),
                        IconButton(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final pickedImage = await picker.pickImage(
                                  source: ImageSource.camera);
                              if (pickedImage != null) {
                                setState(() {
                                  sending = true;
                                });
                                final timeStamp = DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString();
                                FirebaseStorage storage =
                                    FirebaseStorage.instance;
                                Reference ref = storage.ref().child(
                                    'messages/${MessageServices.getConversationId(widget.chatUser.id)}-$timeStamp');
                                await ref.putFile(File(pickedImage.path));
                                String url = await ref.getDownloadURL();
                                Message message = Message(
                                    id: timeStamp,
                                    sender: widget.user.id,
                                    receiver: widget.chatUser.id,
                                    isTagged: isTagged,
                                    taggedMessage: taggedMessage?.id ?? null,
                                    tagType: isTagged ? tagType : null,
                                    text: url,
                                    sentAt: timeStamp,
                                    readAt: '',
                                    type: 'image');
                                setState(() {
                                  taggedMessage = null;
                                  isTagged = false;
                                });
                                await MessageServices.sendMessage(
                                    widget.chatUser, message);

                                setState(() {
                                  sending = false;
                                });
                              }
                            },
                            icon: const Icon(
                              size: 26,
                              Icons.camera_alt_rounded,
                              color: Colors.deepPurple,
                            )),
                        SizedBox(
                          width: mq.width * .02,
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 5.0),
            child: MaterialButton(
              onPressed: () async {
                if (_messageController.text.trim().isNotEmpty) {
                  if (messages.isEmpty) {
                    AuthServices.sendFirstMessage(chatUser: widget.chatUser);
                  }
                  String msg = _messageController.text.trim();
                  Message message = Message(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      sender: widget.user.id,
                      receiver: widget.chatUser.id,
                      isTagged: isTagged,
                      taggedMessage: taggedMessage?.id ?? null,
                      tagType: isTagged ? tagType : null,
                      text: msg,
                      sentAt: DateTime.now().millisecondsSinceEpoch.toString(),
                      readAt: '',
                      type: 'text');
                  _messageController.clear();
                  setState(() {
                    isTagged = false;
                    taggedMessage = null;
                  });
                  await MessageServices.sendMessage(widget.chatUser, message);
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
    );
  }

  Future<void> sendMedia(XFile image, String type) async {
    setState(() {
      sending = true;
    });
    final timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child(
        'messages/${MessageServices.getConversationId(widget.chatUser.id)}/$timeStamp');
    await ref.putFile(File(image.path));
    String url = await ref.getDownloadURL();
    Message message = Message(
        id: timeStamp,
        sender: widget.user.id,
        receiver: widget.chatUser.id,
        isTagged: isTagged,
        taggedMessage: taggedMessage?.id ?? null,
        tagType: isTagged ? tagType : null,
        text: url,
        sentAt: timeStamp,
        readAt: '',
        type: type);
    setState(() {
      isTagged = false;
      taggedMessage = null;
    });
    await MessageServices.sendMessage(widget.chatUser, message);
    setState(() {
      sending = false;
    });
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
                  onTap: () {
                    setState(() {
                      isTagged = true;
                      taggedMessage = message;
                    });
                    Navigator.pop(context);
                    focus.requestFocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      height: mq.height * .05,
                      child: const Row(
                        children: [
                          Icon(Icons.reply),
                          SizedBox(
                            width: 20,
                          ),
                          Text(
                            "Reply",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(),
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
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Edit Message"),
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.black,
                                  )
                                ],
                              ),
                              content: Form(
                                key: _formKey,
                                child: TextFormField(
                                  maxLines: null,
                                  initialValue: message.text,
                                  onSaved: (text) => message.text = text ?? '',
                                  validator: (text) =>
                                      text != null && text.isNotEmpty
                                          ? null
                                          : "Enter Text",
                                  decoration: InputDecoration(
                                      hintText: "Enter your Message",
                                      label: const Text('Message'),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      prefixIcon: const Icon(
                                        Icons.person,
                                        color: Colors.deepPurple,
                                      )),
                                ),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Cancel")),
                                TextButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        _formKey.currentState!.save();
                                        MessageServices.firestore
                                            .collection(
                                                '${MessageServices.messagesCollection}/${MessageServices.getConversationId(widget.chatUser.id)}/messages/')
                                            .doc(message.id)
                                            .update({"text": message.text});
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: const Text("Update")),
                              ],
                            );
                          });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        height: mq.height * .05,
                        child: const Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(
                              width: 20,
                            ),
                            Text(
                              "Edit Message",
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                if (message.sender == widget.user.id) const Divider(),
                if (message.sender == widget.user.id)
                  InkWell(
                    onTap: () {
                      MessageServices.firestore
                          .collection(
                              '${MessageServices.messagesCollection}/${MessageServices.getConversationId(widget.chatUser.id)}/messages/')
                          .doc(message.id)
                          .update({'type': 'deleted'});
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
                  onTap: () {
                    setState(() {
                      isTagged = true;
                      taggedMessage = message;
                    });
                    Navigator.pop(context);
                    focus.requestFocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      height: mq.height * .05,
                      child: const Row(
                        children: [
                          Icon(Icons.reply),
                          SizedBox(
                            width: 20,
                          ),
                          Text(
                            "Reply",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(),
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
                if (message.sender == widget.user.id)
                  InkWell(
                    onTap: () {
                      MessageServices.firestore
                          .collection(
                              '${MessageServices.messagesCollection}/${MessageServices.getConversationId(widget.chatUser.id)}/messages/')
                          .doc(message.id)
                          .update({'type': 'deleted'});
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
                              "Delete Media File",
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

  Future _imageSelection() {
    final mq = MediaQuery.of(context).size;
    return showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (context) => Container(
              width: mq.width,
              height: mq.height * .3,
              margin: const EdgeInsets.all(16),
              child: Card(
                color: Colors.deepPurple,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text(
                      "Select Media File",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                          onTap: () async {
                            final ImagePicker picker = ImagePicker();
                            final List<XFile> images =
                                await picker.pickMultiImage();
                            Navigator.pop(context);
                            for (var image in images) {
                              await sendMedia(image, 'image');
                            }
                          },
                          child: const CircleAvatar(
                              radius: 48,
                              child: Icon(
                                Icons.insert_photo,
                                color: Colors.deepPurple,
                                size: 48,
                              )),
                        ),
                        InkWell(
                          onTap: () async {
                            final ImagePicker _picker = ImagePicker();
                            final XFile? video = await _picker.pickVideo(
                                source: ImageSource.gallery);
                            if (video != null) {
                              Navigator.pop(context);
                              sendMedia(video, 'video');
                            }
                          },
                          child: const CircleAvatar(
                              radius: 48,
                              child: Icon(
                                Icons.video_camera_back_rounded,
                                color: Colors.deepPurple,
                                size: 48,
                              )),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ));
  }
}
