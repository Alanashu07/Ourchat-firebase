import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:our_chat/Widgets/OurChat/status_painter.dart';
import 'package:our_chat/Widgets/open_item.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../Screens/OurChat/my_status_view_screen.dart';
import '../../Screens/OurChat/view_total_statuses.dart';
import '../../Services/auth_services.dart';

class MyStatus extends StatefulWidget {
  final VoidCallback onTap;

  const MyStatus({super.key, required this.onTap});

  @override
  State<MyStatus> createState() => _MyStatusState();
}

class _MyStatusState extends State<MyStatus> {
  VideoPlayerController? controller;

  @override
  void initState() {
    super.initState();
    getThumbnail();
  }

  getThumbnail() async {
    await AuthServices.getCurrentUser();
    final user = AuthServices.currentUser;
    if (user.status.isNotEmpty &&
        user.status[user.status.length - 1].type == 'video') {
      controller = VideoPlayerController.networkUrl(
          Uri.parse(user.status[user.status.length - 1].url));
      await controller!.initialize().then(
        (value) {
          setState(() {});
        },
      );
    }
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
    if (user.status.isEmpty) {
      return GestureDetector(
        onTap: widget.onTap,
        child: ListTile(
          leading: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: SizedBox(
                  height: 55,
                  width: 55,
                  child: CachedNetworkImage(
                    fit: BoxFit.cover,
                    imageUrl: user.image,
                    placeholder: (context, url) =>
                    Center(child: const CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ),
              ),
              const Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      radius: 10,
                      child: Icon(
                        Icons.add,
                        size: 15,
                        color: Colors.white,
                      )))
            ],
          ),
          title: const Text(
            "My Status",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          subtitle: const Text(
            "Click to add Status update",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      );
    } else {
      int max = user.status.length - 1;
      final status = user.status[max];
      final url = status.url;
      return GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              PageTransition(
                  child: MyStatusViewScreen(user: user),
                  type: PageTransitionType.fade));
        },
        child: ListTile(
            leading: CustomPaint(
              painter: StatusPainter(color: Colors.deepPurple, user: user),
              child: Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: status.type == 'video'
                    ? controller == null || !controller!.value.isInitialized ? const SizedBox() : ClipOval(
                        child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: controller!.value.size.width,
                              height: controller!.value.size.height,
                              child: VideoPlayer(controller!),
                            )),
                      )
                    : ClipOval(
                        child: CachedNetworkImage(
                          fit: BoxFit.cover,
                          imageUrl: url,
                          placeholder: (context, url) =>
                          Center(child: const CircularProgressIndicator()),
                          errorWidget: (context, url, error) => Icon(Icons.error),
                        )),
              ),
            ),
            title: const Text(
              "My Status",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            subtitle: const Text(
              "Tap to see your status updates",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            trailing: const OpenItem(
                openChild: ViewTotalStatuses(),
                closedChild: Icon(
                  Icons.more_vert,
                  color: Colors.black,
                ))),
      );
    }
  }
}
