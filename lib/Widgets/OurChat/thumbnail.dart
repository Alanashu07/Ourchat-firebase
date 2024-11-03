import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../Models/message_model.dart';

class Thumbnail extends StatefulWidget {
  final Message media;

  const Thumbnail({super.key, required this.media});

  @override
  State<Thumbnail> createState() => _ThumbnailState();
}

class _ThumbnailState extends State<Thumbnail> {
  VideoPlayerController? controller;

  @override
  void initState() {
    getThumbnail();
    super.initState();
  }

  Future<void> getThumbnail() async {
    if (widget.media.type == 'video') {
      controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.media.text));
      await controller!.initialize();
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
    return SizedBox(
      height: 200,
      width: 200,
      child: widget.media.type == 'video'
          ? FutureBuilder(
              future: getThumbnail(),
              builder: (context, snapshot) {
                return !controller!.value.isInitialized
                    ? Container(
                        alignment: Alignment.center,
                        color: Colors.deepPurple.shade100,
                        child: const CircularProgressIndicator())
                    : FittedBox(
                        fit: BoxFit.cover, // Cover the entire container
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: controller!.value.size.width,
                              height: controller!.value.size.height,
                              child: VideoPlayer(controller!),
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
                      );
              },
            )
          : CachedNetworkImage(
              fit: BoxFit.cover,
              imageUrl: widget.media.text,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
    );
  }
}
