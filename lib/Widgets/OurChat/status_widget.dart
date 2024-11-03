import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../Models/status_model.dart';
import '../../Models/user_model.dart';

class StatusWidget extends StatefulWidget {
  final User user;
  final Status status;

  const StatusWidget({super.key, required this.user, required this.status});

  @override
  State<StatusWidget> createState() => _StatusWidgetState();
}

class _StatusWidgetState extends State<StatusWidget> {
  VideoPlayerController? videoPlayerController;

  @override
  void initState() {
    if (widget.status.type == 'video') {
      videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(widget.status.url));
      videoPlayerController!.initialize().then((_) => setState(() {}));
      videoPlayerController!.setLooping(false);
      videoPlayerController!.setVolume(1);
      videoPlayerController!.play();
    }
    super.initState();
  }

  @override
  void dispose() {
    if (videoPlayerController != null) {
      videoPlayerController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: widget.status.type == 'image'
          ? CachedNetworkImage(
              imageUrl: widget.status.url,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
            )
          : videoPlayerController!.value.isInitialized
              ? AspectRatio(
                  aspectRatio: videoPlayerController!.value.aspectRatio,
                  child: VideoPlayer(videoPlayerController!),
                )
              : const CircularProgressIndicator(),
    );
  }
}
