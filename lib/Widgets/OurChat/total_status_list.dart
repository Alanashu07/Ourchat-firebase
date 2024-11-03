import 'package:flutter/material.dart';
import 'package:our_chat/Constants/alerts.dart';
import 'package:our_chat/Services/auth_services.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../Constants/date_format.dart';
import '../../Screens/OurChat/my_status_view_screen.dart';

class TotalStatusList extends StatefulWidget {
  final int index;

  const TotalStatusList({super.key, required this.index});

  @override
  State<TotalStatusList> createState() => _TotalStatusListState();
}

class _TotalStatusListState extends State<TotalStatusList> {
  VideoPlayerController? controller;

  getThumbnail() async {
    await AuthServices.getCurrentUser();
    final user = AuthServices.currentUser;
    if (user.status[widget.index].type == 'video') {
      controller = VideoPlayerController.networkUrl(
          Uri.parse(user.status[widget.index].url));
      await controller!.initialize();
      setState(() {});
    }
  }

  @override
  void initState() {
    getThumbnail();
    super.initState();
  }

  @override
  void dispose() {
    if (controller != null) {
      controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthServices>().user;
    final status = user.status[widget.index];
    final url = status.url;
    final users = status.users;
    final time = status.time;
    return ListTile(
      onTap: () {
        Navigator.push(
            context,
            PageTransition(
                child: MyStatusViewScreen(
                  user: user,
                  initialIndex: widget.index,
                ),
                type: PageTransitionType.fade));
      },
      leading: Container(
        width: 54,
        height: 54,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: status.type == 'video'
            ? controller == null || !controller!.value.isInitialized
                ? const SizedBox()
                : ClipOval(
                    child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller!.value.size.width,
                          height: controller!.value.size.height,
                          child: VideoPlayer(controller!),
                        )),
                  )
            : ClipOval(
                child: Image.network(
                url,
                fit: BoxFit.cover,
              )),
      ),
      title: Text(
        "${users.length.toString()} views",
        style:
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
      subtitle: Text(
        DateFormat.getMessageTime(context: context, time: time),
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
      trailing: IconButton(
          onPressed: () {
            confirmDelete(
                context: context,
                content: "Status update will be deleted",
                delete: () {
                  AuthServices.deleteStatus(status);
                  context.read<AuthServices>().deleteStatusLocally(status);
                  Navigator.pop(context);
                  if (user.status.isEmpty) {
                    Navigator.pop(context);
                  }
                });
          },
          icon: const Icon(
            Icons.delete_forever,
            color: Colors.black,
          )),
    );
  }
}
