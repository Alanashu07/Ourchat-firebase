import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:our_chat/Models/status_model.dart';
import 'package:our_chat/Models/user_model.dart';
import 'package:our_chat/Services/auth_services.dart';
import 'package:our_chat/Services/message_services.dart';
import 'package:our_chat/Widgets/open_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../Constants/alerts.dart';
import '../../Constants/date_format.dart';
import '../../Models/message_model.dart';
import '../../Screens/image_viewer.dart';
import '../../Screens/video_viewer.dart';

class ChatBubble extends StatefulWidget {
  final Message message;
  final User chatUser;
  final Message? taggedMessage;

  const ChatBubble(
      {super.key,
      required this.message,
      required this.chatUser,
      this.taggedMessage});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  VideoPlayerController? _videoPlayerController;
  VideoPlayerController? _taggedController;
  Message? taggedMessage;
  Status? taggedStatus;

  @override
  void initState() {
    if (widget.message.type == 'video') {
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(widget.message.text))
            ..initialize().then((_) => setState(() {}));
      _videoPlayerController!.setLooping(false);
      _videoPlayerController!.setVolume(1);
    }
    getMessageFromTag();
    super.initState();
  }

  @override
  void dispose() {
    if (_videoPlayerController != null) {
      _videoPlayerController!.dispose();
    }
    if (_taggedController != null) {
      _taggedController!.dispose();
    }
    super.dispose();
  }

  Future<void> getTaggedMessage() async {
    if (widget.message.taggedMessage != null &&
        widget.message.tagType == 'message') {
      taggedMessage = await MessageServices.getTaggedMessage(
          widget.message.taggedMessage!, widget.chatUser);
      // setState(() {});
      if (taggedMessage!.type == 'video') {
        _taggedController =
            VideoPlayerController.networkUrl(Uri.parse(taggedMessage!.text));
        await _taggedController!.initialize();
      }
    }
  }

  Future<void> getMessageFromTag() async {
    if (widget.taggedMessage != null && widget.taggedMessage!.type == 'video') {
      _taggedController =
          VideoPlayerController.networkUrl(Uri.parse(widget.taggedMessage!.text));
      await _taggedController!.initialize().then(
        (value) {
          setState(() {});
        },
      );
    }
  }

  Future<void> getTaggedStatus() async {
    if (widget.message.taggedMessage != null &&
            widget.message.tagType == 'status' ||
        widget.message.tagType == 'statusImage' ||
        widget.message.tagType == 'statusVideo') {
      final currentUser = AuthServices.currentUser;
      final user = widget.message.receiver == currentUser.id
          ? currentUser
          : widget.chatUser;
      taggedStatus = user.status.firstWhere(
        (element) => element.id == widget.message.taggedMessage,
        orElse: () => throw Exception("No match found"),
      );
      if (widget.message.tagType == 'statusVideo') {
        _taggedController =
            VideoPlayerController.networkUrl(Uri.parse(taggedStatus!.url));
        await _taggedController!.initialize();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthServices.currentUser;
    return user.id == widget.message.sender ? sendBubble() : receiveBubble();
  }

  Widget sendBubble() {
    final mq = MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              widget.message.isUploaded != null && !widget.message.isUploaded!
                  ? const Icon(
                      Icons.access_time,
                      color: Colors.black54,
                      size: 15,
                    )
                  : widget.message.readAt.isNotEmpty
                      ? const Icon(Icons.done_all, color: Colors.deepPurple)
                      : widget.message.sentAt.isNotEmpty
                          ? const Icon(Icons.done, color: Colors.deepPurple)
                          : const SizedBox(),
              const SizedBox(
                width: 10,
              ),
              Text(DateFormat.getFormattedTime(
                  context: context, time: widget.message.sentAt)),
            ],
          ),
        ),
        Flexible(
          child: Container(
              padding: EdgeInsets.all(mq.width * .04),
              margin: EdgeInsets.symmetric(
                  horizontal: mq.width * .04, vertical: mq.height * .01),
              decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  border: Border.all(color: Colors.deepPurple),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                  )),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.message.taggedMessage != null &&
                      widget.message.isTagged!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        width: mq.width,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: widget.message.tagType == 'message'
                            ? widget.taggedMessage != null
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (widget.taggedMessage!.type !=
                                          'deleted')
                                        Text(
                                          widget.taggedMessage!.sender ==
                                                  AuthServices.currentUser.id
                                              ? 'You'
                                              : widget.chatUser.name,
                                          style: TextStyle(
                                              color: widget.taggedMessage!
                                                          .sender ==
                                                      AuthServices
                                                          .currentUser.id
                                                  ? Colors.deepPurple
                                                  : Colors.lightBlue,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      widget.taggedMessage!.type == 'image' ||
                                              widget.taggedMessage!.type ==
                                                  'gif'
                                          ? SizedBox(
                                              height: 50,
                                              width: 50,
                                              child: CachedNetworkImage(
                                                fit: BoxFit.cover,
                                                imageUrl:
                                                    widget.taggedMessage!.text,
                                                placeholder: (context, url) =>
                                                    const Center(
                                                        child:
                                                            CircularProgressIndicator()),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Icon(Icons.error),
                                              ),
                                            )
                                          : widget.taggedMessage!.type ==
                                                  'video'
                                              ? _taggedController == null || !_taggedController!
                                                      .value.isInitialized
                                                  ? Container(
                                                      height: 50,
                                                      width: 50,
                                                      alignment:
                                                          Alignment.center,
                                                      child:
                                                          const CircularProgressIndicator())
                                                  : SizedBox(
                                                      height: 50,
                                                      width: 50,
                                                      child: Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          FittedBox(
                                                            fit: BoxFit.cover,
                                                            // Cover the entire container
                                                            child: SizedBox(
                                                              width: 50,
                                                              height: 50,
                                                              child: VideoPlayer(
                                                                  _taggedController!),
                                                            ),
                                                          ),
                                                          const CircleAvatar(
                                                            radius: 10,
                                                            backgroundColor:
                                                                Colors.white70,
                                                            child: Icon(
                                                              Icons.play_arrow,
                                                              size: 15,
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    )
                                              : Text(
                                                  widget.taggedMessage!.type ==
                                                          'deleted'
                                                      ? 'This message was deleted'
                                                      : widget
                                                          .taggedMessage!.text,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black54),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                    ],
                                  )
                                : FutureBuilder(
                                    future: getTaggedMessage(),
                                    builder: (context, snapshot) {
                                      // if (snapshot.connectionState ==
                                      //     ConnectionState.waiting) {
                                      //   return const SizedBox();
                                      // }
                                      return taggedMessage == null
                                          ? Text(
                                              'This message was deleted',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (taggedMessage!.type !=
                                                    'deleted')
                                                  Text(
                                                    taggedMessage!.sender ==
                                                            AuthServices
                                                                .currentUser.id
                                                        ? 'You'
                                                        : widget.chatUser.name,
                                                    style: TextStyle(
                                                        color: taggedMessage!
                                                                    .sender ==
                                                                AuthServices
                                                                    .currentUser
                                                                    .id
                                                            ? Colors.deepPurple
                                                            : Colors.lightBlue,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                taggedMessage!.type ==
                                                            'image' ||
                                                        taggedMessage!.type ==
                                                            'gif'
                                                    ? SizedBox(
                                                        height: 50,
                                                        width: 50,
                                                        child:
                                                            CachedNetworkImage(
                                                          fit: BoxFit.cover,
                                                          imageUrl:
                                                              taggedMessage!
                                                                  .text,
                                                          placeholder: (context,
                                                                  url) =>
                                                              const Center(
                                                                  child:
                                                                      CircularProgressIndicator()),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              Icon(Icons.error),
                                                        ),
                                                      )
                                                    : taggedMessage!.type ==
                                                            'video'
                                                        ? !_taggedController!
                                                                .value
                                                                .isInitialized
                                                            ? Container(
                                                                height: 50,
                                                                width: 50,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child:
                                                                    const CircularProgressIndicator())
                                                            : SizedBox(
                                                                height: 50,
                                                                width: 50,
                                                                child: Stack(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  children: [
                                                                    FittedBox(
                                                                      fit: BoxFit
                                                                          .cover,
                                                                      // Cover the entire container
                                                                      child:
                                                                          SizedBox(
                                                                        width:
                                                                            50,
                                                                        height:
                                                                            50,
                                                                        child: VideoPlayer(
                                                                            _taggedController!),
                                                                      ),
                                                                    ),
                                                                    const CircleAvatar(
                                                                      radius:
                                                                          10,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .white70,
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .play_arrow,
                                                                        size:
                                                                            15,
                                                                      ),
                                                                    )
                                                                  ],
                                                                ),
                                                              )
                                                        : Text(
                                                            taggedMessage!
                                                                        .type ==
                                                                    'deleted'
                                                                ? 'This message was deleted'
                                                                : taggedMessage!
                                                                    .text,
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .black54),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                              ],
                                            );
                                    },
                                  )
                            : FutureBuilder(
                                future: getTaggedStatus(),
                                builder: (context, snapshot) {
                                  // if(snapshot.connectionState == ConnectionState.waiting) {
                                  //   return const SizedBox();
                                  // }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                          text: TextSpan(children: [
                                        TextSpan(
                                            text: widget.chatUser.name,
                                            style: const TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14)),
                                        TextSpan(
                                            text: '  •  Status',
                                            style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold))
                                      ])),
                                      taggedStatus != null
                                          ? widget.message.tagType ==
                                                  'statusImage'
                                              ? SizedBox(
                                                  height: 50,
                                                  width: 50,
                                                  child: CachedNetworkImage(
                                                    fit: BoxFit.cover,
                                                    imageUrl: taggedStatus!.url,
                                                    placeholder: (context,
                                                            url) =>
                                                        const Center(
                                                            child:
                                                                CircularProgressIndicator()),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            Icon(Icons.error),
                                                  ),
                                                )
                                              : widget.message.tagType ==
                                                      'statusVideo'
                                                  ? !_taggedController!
                                                          .value.isInitialized
                                                      ? Container(
                                                          height: 50,
                                                          width: 50,
                                                          alignment:
                                                              Alignment.center,
                                                          child:
                                                              const CircularProgressIndicator())
                                                      : SizedBox(
                                                          height: 50,
                                                          width: 50,
                                                          child: Stack(
                                                            alignment: Alignment
                                                                .center,
                                                            children: [
                                                              FittedBox(
                                                                fit: BoxFit
                                                                    .cover,
                                                                // Cover the entire container
                                                                child: SizedBox(
                                                                  width: 50,
                                                                  height: 50,
                                                                  child: VideoPlayer(
                                                                      _taggedController!),
                                                                ),
                                                              ),
                                                              const CircleAvatar(
                                                                radius: 10,
                                                                backgroundColor:
                                                                    Colors
                                                                        .white70,
                                                                child: Icon(
                                                                  Icons
                                                                      .play_arrow,
                                                                  size: 15,
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        )
                                                  : Text(
                                                      'Replied to their status.',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.black54),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    )
                                          : Text(
                                              'Replied to their status.',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                    ],
                                  );
                                },
                              ),
                      ),
                    ),
                  widget.message.type == 'image' || widget.message.type == 'gif'
                      ? OpenContainer(
                          openColor: Colors.transparent,
                          closedColor: Colors.transparent,
                          openElevation: 0,
                          closedElevation: 0,
                          closedBuilder: (context, action) => SizedBox(
                            height: mq.height * .25,
                            width: mq.height * .25,
                            child: CachedNetworkImage(
                              fit: BoxFit.cover,
                              imageUrl: widget.message.text,
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            ),
                          ),
                          openBuilder: (context, action) => ImageViewer(
                              title: "Image", image: widget.message.text),
                        )
                      : widget.message.type == 'video'
                          ? OpenItem(
                              openChild:
                                  VideoMessageViewer(message: widget.message),
                              closedChild: _videoPlayerController == null ||
                                      !_videoPlayerController!
                                          .value.isInitialized
                                  ? Container(
                                      height: mq.height * .25,
                                      width: mq.height * .25,
                                      alignment: Alignment.center,
                                      child: const CircularProgressIndicator())
                                  : SizedBox(
                                      height: mq.height * .25,
                                      width: mq.height * .25,
                                      child: FittedBox(
                                        fit: BoxFit
                                            .cover, // Cover the entire container
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              width: _videoPlayerController!
                                                  .value.size.width,
                                              height: _videoPlayerController!
                                                  .value.size.height,
                                              child: VideoPlayer(
                                                  _videoPlayerController!),
                                            ),
                                            const CircleAvatar(
                                              radius: 50,
                                              backgroundColor: Colors.white70,
                                              child: Icon(
                                                Icons.play_arrow,
                                                size: 70,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ))
                          : Linkify(
                              text: widget.message.text,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 15),
                              linkStyle: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 15,
                                  decorationColor: Colors.blue,
                                  decoration: TextDecoration.underline),
                              onOpen: (link) async {
                                try {
                                  final uri = Uri.parse(link.url);
                                  launchUrl(uri);
                                } catch (e) {
                                  showSnackBar(
                                      context: context,
                                      content: 'Cannot launch Url: $e',
                                      color: Colors.red);
                                }
                              },
                            )
                ],
              )),
        )
      ],
    );
  }

  Widget receiveBubble() {
    final mq = MediaQuery.of(context).size;
    if (widget.message.readAt.isEmpty) {
      MessageServices.updateReadStatus(widget.message);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
              padding: EdgeInsets.all(mq.width * .04),
              margin: EdgeInsets.symmetric(
                  horizontal: mq.width * .04, vertical: mq.height * .01),
              decoration: BoxDecoration(
                  color: Colors.lightBlue.shade100,
                  border: Border.all(color: Colors.lightBlue),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  )),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.message.taggedMessage != null &&
                      widget.message.isTagged!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        width: mq.width,
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: widget.message.tagType == 'message'
                            ? widget.taggedMessage != null ? Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            if (widget.taggedMessage!.type !=
                                'deleted')
                              Text(
                                widget.taggedMessage!.sender ==
                                    AuthServices
                                        .currentUser.id
                                    ? 'You'
                                    : widget.chatUser.name,
                                style: TextStyle(
                                    color:
                                    widget.taggedMessage!.sender ==
                                        AuthServices
                                            .currentUser
                                            .id
                                        ? Colors.deepPurple
                                        : Colors.lightBlue,
                                    fontSize: 14,
                                    fontWeight:
                                    FontWeight.bold),
                              ),
                            widget.taggedMessage!.type == 'image' ||
                                widget.taggedMessage!.type == 'gif'
                                ? SizedBox(
                              height: 50,
                              width: 50,
                              child: CachedNetworkImage(
                                fit: BoxFit.cover,
                                imageUrl:
                                widget.taggedMessage!.text,
                                placeholder: (context,
                                    url) =>
                                const Center(
                                    child:
                                    CircularProgressIndicator()),
                                errorWidget: (context,
                                    url, error) =>
                                    Icon(Icons.error),
                              ),
                            )
                                : widget.taggedMessage!.type == 'video'
                                ? _taggedController == null || !_taggedController!
                                .value.isInitialized
                                ? Container(
                                height: 50,
                                width: 50,
                                alignment: Alignment
                                    .center,
                                child:
                                const CircularProgressIndicator())
                                : SizedBox(
                              height: 50,
                              width: 50,
                              child: Stack(
                                alignment:
                                Alignment
                                    .center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit
                                        .cover,
                                    // Cover the entire container
                                    child:
                                    SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: VideoPlayer(
                                          _taggedController!),
                                    ),
                                  ),
                                  const CircleAvatar(
                                    radius: 10,
                                    backgroundColor:
                                    Colors
                                        .white70,
                                    child: Icon(
                                      Icons
                                          .play_arrow,
                                      size: 15,
                                    ),
                                  )
                                ],
                              ),
                            )
                                : Text(
                              widget.taggedMessage!.type ==
                                  'deleted'
                                  ? 'This message was deleted'
                                  : widget.taggedMessage!
                                  .text,
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                  Colors.black54),
                              maxLines: 2,
                              overflow: TextOverflow
                                  .ellipsis,
                            ),
                          ],
                        ) : FutureBuilder(
                                future: getTaggedMessage(),
                                builder: (context, snapshot) {
                                  return taggedMessage == null
                                      ? Text(
                                          'This message was deleted',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (taggedMessage!.type !=
                                                'deleted')
                                              Text(
                                                taggedMessage!.sender ==
                                                        AuthServices
                                                            .currentUser.id
                                                    ? 'You'
                                                    : widget.chatUser.name,
                                                style: TextStyle(
                                                    color:
                                                        taggedMessage!.sender ==
                                                                AuthServices
                                                                    .currentUser
                                                                    .id
                                                            ? Colors.deepPurple
                                                            : Colors.lightBlue,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            taggedMessage!.type == 'image' ||
                                                    taggedMessage!.type == 'gif'
                                                ? SizedBox(
                                                    height: 50,
                                                    width: 50,
                                                    child: CachedNetworkImage(
                                                      fit: BoxFit.cover,
                                                      imageUrl:
                                                          taggedMessage!.text,
                                                      placeholder: (context,
                                                              url) =>
                                                          const Center(
                                                              child:
                                                                  CircularProgressIndicator()),
                                                      errorWidget: (context,
                                                              url, error) =>
                                                          Icon(Icons.error),
                                                    ),
                                                  )
                                                : taggedMessage!.type == 'video'
                                                    ? !_taggedController!
                                                            .value.isInitialized
                                                        ? Container(
                                                            height: 50,
                                                            width: 50,
                                                            alignment: Alignment
                                                                .center,
                                                            child:
                                                                const CircularProgressIndicator())
                                                        : SizedBox(
                                                            height: 50,
                                                            width: 50,
                                                            child: Stack(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              children: [
                                                                FittedBox(
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  // Cover the entire container
                                                                  child:
                                                                      SizedBox(
                                                                    width: 50,
                                                                    height: 50,
                                                                    child: VideoPlayer(
                                                                        _taggedController!),
                                                                  ),
                                                                ),
                                                                const CircleAvatar(
                                                                  radius: 10,
                                                                  backgroundColor:
                                                                      Colors
                                                                          .white70,
                                                                  child: Icon(
                                                                    Icons
                                                                        .play_arrow,
                                                                    size: 15,
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          )
                                                    : Text(
                                                        taggedMessage!.type ==
                                                                'deleted'
                                                            ? 'This message was deleted'
                                                            : taggedMessage!
                                                                .text,
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                Colors.black54),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                          ],
                                        );
                                },
                              )
                            : FutureBuilder(
                                future: getTaggedStatus(),
                                builder: (context, snapshot) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                          text: TextSpan(children: [
                                        TextSpan(
                                            text: "You",
                                            style: const TextStyle(
                                                color: Colors.deepPurple,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14)),
                                        TextSpan(
                                            text: '  •  Status',
                                            style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold))
                                      ])),
                                      taggedStatus != null
                                          ? widget.message.tagType ==
                                                  'statusImage'
                                              ? SizedBox(
                                                  height: 50,
                                                  width: 50,
                                                  child: CachedNetworkImage(
                                                    fit: BoxFit.cover,
                                                    imageUrl: taggedStatus!.url,
                                                    placeholder: (context,
                                                            url) =>
                                                        const Center(
                                                            child:
                                                                CircularProgressIndicator()),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            Icon(Icons.error),
                                                  ),
                                                )
                                              : widget.message.tagType ==
                                                      'statusVideo'
                                                  ? !_taggedController!
                                                          .value.isInitialized
                                                      ? Container(
                                                          height: 50,
                                                          width: 50,
                                                          alignment:
                                                              Alignment.center,
                                                          child:
                                                              const CircularProgressIndicator())
                                                      : SizedBox(
                                                          height: 50,
                                                          width: 50,
                                                          child: Stack(
                                                            alignment: Alignment
                                                                .center,
                                                            children: [
                                                              FittedBox(
                                                                fit: BoxFit
                                                                    .cover,
                                                                // Cover the entire container
                                                                child: SizedBox(
                                                                  width: 50,
                                                                  height: 50,
                                                                  child: VideoPlayer(
                                                                      _taggedController!),
                                                                ),
                                                              ),
                                                              const CircleAvatar(
                                                                radius: 10,
                                                                backgroundColor:
                                                                    Colors
                                                                        .white70,
                                                                child: Icon(
                                                                  Icons
                                                                      .play_arrow,
                                                                  size: 15,
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        )
                                                  : Text(
                                                      'Replied to your status.',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.black54),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    )
                                          : Text(
                                              'Replied to your status.',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                    ],
                                  );
                                },
                              ),
                      ),
                    ),
                  widget.message.type == 'image' || widget.message.type == 'gif'
                      ? OpenContainer(
                          openColor: Colors.transparent,
                          closedColor: Colors.transparent,
                          openElevation: 0,
                          closedElevation: 0,
                          closedBuilder: (context, action) => SizedBox(
                            height: mq.height * .25,
                            width: mq.height * .25,
                            child: CachedNetworkImage(
                              fit: BoxFit.cover,
                              imageUrl: widget.message.text,
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            ),
                          ),
                          openBuilder: (context, action) => ImageViewer(
                              title: "Image", image: widget.message.text),
                        )
                      : widget.message.type == 'video'
                          ? GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => VideoMessageViewer(
                                            message: widget.message)));
                              },
                              child: OpenItem(
                                  openChild: VideoMessageViewer(
                                      message: widget.message),
                                  closedChild: _videoPlayerController == null ||
                                          !_videoPlayerController!
                                              .value.isInitialized
                                      ? Container(
                                          height: mq.height * .25,
                                          width: mq.height * .25,
                                          alignment: Alignment.center,
                                          child:
                                              const CircularProgressIndicator())
                                      : SizedBox(
                                          height: mq.height * .25,
                                          width: mq.height * .25,
                                          child: FittedBox(
                                            fit: BoxFit
                                                .cover, // Cover the entire container
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                SizedBox(
                                                  width: _videoPlayerController!
                                                      .value.size.width,
                                                  height:
                                                      _videoPlayerController!
                                                          .value.size.height,
                                                  child: VideoPlayer(
                                                      _videoPlayerController!),
                                                ),
                                                const CircleAvatar(
                                                  radius: 50,
                                                  backgroundColor:
                                                      Colors.white70,
                                                  child: Icon(
                                                    Icons.play_arrow,
                                                    size: 70,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        )),
                            )
                          : Linkify(
                              text: widget.message.text,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 15),
                              linkStyle: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 15,
                                  decorationColor: Colors.blue,
                                  decoration: TextDecoration.underline),
                              onOpen: (link) async {
                                try {
                                  final uri = Uri.parse(link.url);
                                  launchUrl(uri);
                                } catch (e) {
                                  showSnackBar(
                                      context: context,
                                      content: 'Cannot launch Url: $e',
                                      color: Colors.red);
                                }
                              },
                            ),
                ],
              )),
        ),
        Text(DateFormat.getFormattedTime(
            context: context, time: widget.message.sentAt))
      ],
    );
  }
}
