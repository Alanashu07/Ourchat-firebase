import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:our_chat/Constants/date_format.dart';
import 'package:our_chat/Models/message_model.dart';
import 'package:our_chat/Models/user_model.dart';
import 'package:our_chat/Screens/image_viewer.dart';
import 'package:our_chat/Screens/video_viewer.dart';
import 'package:our_chat/Services/auth_services.dart';
import 'package:our_chat/Services/message_services.dart';
import 'package:our_chat/Widgets/OurChat/thumbnail.dart';
import 'package:our_chat/Widgets/open_item.dart';
import 'package:provider/provider.dart';

class UserDetails extends StatefulWidget {
  final User chatUser;

  const UserDetails({super.key, required this.chatUser});

  @override
  State<UserDetails> createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
  List<Message>? messages;
  List<Message>? medias;

  getMedias() async {
    final snap = await MessageServices.firestore
        .collection(
            '${MessageServices.messagesCollection}/${MessageServices.getConversationId(widget.chatUser.id)}/messages/')
        .where('type', isNotEqualTo: 'text')
        .get();
    print(snap);
    final data = snap.docs;
    messages = data.map((e) => Message.fromJson(e.data())).toList();
    medias = messages!
        .where(
          (element) => element.type != 'deleted',
        )
        .toList();
    medias!.sort(
      (b, a) => a.sentAt.compareTo(b.sentAt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    AuthServices.getAllUsers();
    final user = context.watch<AuthServices>().allUsers.firstWhere(
          (element) => element.id == widget.chatUser.id,
        );
    return Scaffold(
      body: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: mq.height * .1,
                  ),
                  OpenItem(
                    openChild: ImageViewer(title: user.name, image: user.image),
                    closedChild: SizedBox(
                      height: 120,
                      width: 120,
                      child: ClipOval(
                          child: CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: widget.chatUser.image,
                            placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                          )),
                    ),
                  ),
                  SizedBox(
                    height: mq.height * .02,
                  ),
                  Text(
                    user.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 14),
                  ),
                  SizedBox(
                    height: mq.height * .02,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "About: ",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(user.about)
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(DateFormat.getLastActiveTime(
                      context: context, lastActive: user.lastActive)),
                  FutureBuilder(
                    future: getMedias(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          alignment: Alignment.center,
                          height: mq.width,
                          width: mq.width,
                          child: CircularProgressIndicator(),
                        );
                      }
                      return medias == null || medias!.isEmpty ? SizedBox(
                        height: mq.width,
                      ) : GridView.builder(
                        itemCount: medias!.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2),
                        itemBuilder: (context, index) {
                          Message media = medias![index];
                          return Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: OpenItem(
                              openChild:
                                  media.type == 'image' || media.type == 'gif'
                                      ? ImageViewer(
                                          title: "Image", image: media.text)
                                      : VideoMessageViewer(message: media),
                              closedChild: Thumbnail(media: media),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(
                    height: mq.width * .05,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Joined On: "),
                      Text(DateFormat.getCreatedTime(
                          context: context, time: user.joinedOn))
                    ],
                  ),
                  SizedBox(
                    height: mq.height * .1,
                  )
                ],
              ),
            ),
    );
  }
}
