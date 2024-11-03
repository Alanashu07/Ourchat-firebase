import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../Models/message_model.dart';

class VideoMessageViewer extends StatefulWidget {
  final Message message;

  const VideoMessageViewer({
    super.key,
    required this.message,
  });

  @override
  State<VideoMessageViewer> createState() => _VideoMessageViewerState();
}

class _VideoMessageViewerState extends State<VideoMessageViewer> {
  late VideoPlayerController _videoPlayerController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.message.text))
          ..initialize().then((_) {
            setState(() {});
            _videoPlayerController.setLooping(true);
            _videoPlayerController.setVolume(1);
          });
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_videoPlayerController.value.isInitialized) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    if (_timer != null) {
      _timer!.cancel();
    }
    super.dispose();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          !_videoPlayerController.value.isInitialized ? const Center(child: CircularProgressIndicator()) :AspectRatio(
            aspectRatio: _videoPlayerController.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController),
          ),
          Align(
              alignment: Alignment.center,
              child: CircleAvatar(
                  radius: 33,
                  backgroundColor: Colors.black38,
                  child: IconButton(
                      onPressed: () {
                        setState(() {
                          _videoPlayerController.value.isPlaying
                              ? _videoPlayerController.pause()
                              : _videoPlayerController.play();
                        });
                      },
                      icon: Icon(
                        _videoPlayerController.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 50,
                        color: Colors.white,
                      )))),
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatDuration(_videoPlayerController.value.position),
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                        ),
                        Text(
                          formatDuration(_videoPlayerController.value.duration),
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Slider(
                      min: 0.0,
                      max: _videoPlayerController.value.duration.inSeconds
                          .toDouble(),
                      value: _videoPlayerController.value.position.inSeconds
                          .toDouble(),
                      onChanged: (value) {
                        setState(() {
                          _videoPlayerController
                              .seekTo(Duration(seconds: value.toInt()));
                        });
                      }),
                ],
              ))
        ],
      ),
    );
  }
}
