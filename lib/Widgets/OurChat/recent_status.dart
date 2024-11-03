import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:our_chat/Constants/date_format.dart';
import 'package:our_chat/Services/auth_services.dart';
import 'package:our_chat/Widgets/OurChat/status_painter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../../Models/user_model.dart';
import '../../Screens/OurChat/status_view_screen.dart';

class RecentStatus extends StatefulWidget {
  final User user;

  const RecentStatus({super.key, required this.user});

  @override
  State<RecentStatus> createState() => _RecentStatusState();
}

class _RecentStatusState extends State<RecentStatus> {
  VideoPlayerController? controller;

  @override
  void initState() {
    super.initState();
    getThumbnail();
  }

  getThumbnail() async {
    final lastStatus = widget.user.status[widget.user.status.length - 1];
    if(lastStatus.type == 'video') {
      controller = VideoPlayerController.networkUrl(Uri.parse(lastStatus.url));
      await controller!.initialize().then((_) {
        setState(() {});
      });
    }
  }


  @override
  void dispose() {
    if(controller != null) {
      controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthServices>(context).user;
    final int max = widget.user.status.length - 1;
    final status = widget.user.status[max];
    final url = status.url;
    final time = status.time;
    bool viewedByUser = status.users.contains(user.id);
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            PageTransition(
                child: StatusViewScreen(user: widget.user),
                type: PageTransitionType.fade));
      },
      child: ListTile(
        leading: CustomPaint(
          painter: StatusPainter(color: viewedByUser ? Colors.grey :Colors.deepPurple, user: widget.user),
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
        title: Text(
          widget.user.name,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        subtitle: Text(
          DateFormat.getMessageTime(context: context, time: time),
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }
}
