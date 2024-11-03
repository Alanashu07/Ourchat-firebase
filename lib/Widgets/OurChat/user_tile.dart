import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:our_chat/Screens/image_viewer.dart';
import 'package:our_chat/Services/auth_services.dart';
import 'package:our_chat/Services/message_services.dart';
import 'package:our_chat/Widgets/open_item.dart';
import '../../Constants/date_format.dart';
import '../../Models/message_model.dart';
import '../../Models/user_model.dart';

class UserTile extends StatelessWidget {
  final Color color;
  final User user;

  const UserTile({super.key, required this.color, required this.user});

  @override
  Widget build(BuildContext context) {
    Message? message;
    return StreamBuilder(
        stream: MessageServices.getLastMessage(user),
        builder: (context, snapshot) {
          final data = snapshot.data?.docs;
          final list =
              data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
          if (data != null && list.isNotEmpty) message = list[0];
          return AnimatedContainer(
            duration: 200.ms,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: color),
              color: color.withOpacity(.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                OpenItem(
                  openChild: ImageViewer(title: user.name, image: user.image),
                  closedChild: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: SizedBox(
                          height: 40,
                          width: 40,
                          child: CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: user.image,
                            placeholder: (context, url) =>
                            Center(child: const CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                          ),
                        ),
                      ),
                      if(user.isOnline)
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: Colors.green,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      message != null
                          ? message!.sender == AuthServices.currentUser.id
                              ? message!.type == 'text'
                                  ? 'You: ${message!.text}'
                                  : message!.type == 'image' ? 'You: Sent an image 📸' : message!.type == 'video' ? 'You: Sent a video🎥' : 'This message was deleted!'
                              : message!.type == 'text'
                                  ? message!.text
                                  : message!.type == 'image' ? 'Sent an image 📸' : message!.type == 'video' ? 'Sent a video🎥' : 'This message was deleted!'
                          : user.about,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                )),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(DateFormat.getFormattedTime(
                        context: context,
                        time: message != null
                            ? message!.sentAt
                            : user.lastActive)),
                    if (message != null &&
                            message!.readAt.isEmpty &&
                            message!.sender != AuthServices.currentUser.id) const CircleAvatar(
                            radius: 6,
                            backgroundColor: Colors.deepOrange,
                          )
                  ],
                )
              ],
            ),
          );
        });
  }
}
