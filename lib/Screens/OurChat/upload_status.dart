import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../Constants/date_format.dart';
import '../../Models/status_model.dart';
import '../../Services/auth_services.dart';

class UploadStatus extends StatefulWidget {
  final String url;
  final String id;
  final String type;
  const UploadStatus({super.key, required this.url, required this.id, required this.type});

  @override
  State<UploadStatus> createState() => _UploadStatusState();
}

class _UploadStatusState extends State<UploadStatus> {
  TextEditingController caption = TextEditingController();
  late VideoPlayerController _videoPlayerController;
  bool isSending = false;

  Future<void> sendStatus(BuildContext context) async {
    Status status = Status(
        url: widget.url,
        id: widget.id,
        type: widget.type,
        caption: caption.text.trim().isEmpty ? null : caption.text.trim(),
        time: DateFormat.getNow(),
        users: []);
    await AuthServices.updateUserStatus(status: status);
    context.read<AuthServices>().updateUserStatusLocally(status: status);
  }

  @override
  void initState() {
    if (widget.type == 'video') {
      _videoPlayerController =
      VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          setState(() {});
          _videoPlayerController.setLooping(true);
          _videoPlayerController.setVolume(1);
        });
    }
    super.initState();
  }

  @override
  void dispose() {
    if (widget.type == 'video') {
      _videoPlayerController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Stack(
        children: [
          widget.type == 'image' ? Center(child: Image.network(widget.url)) : Center(
            child: Stack(
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
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
              child: Padding(
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
                      child: TextFormField(
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: 5,
                        controller: caption,
                        decoration: const InputDecoration(
                            hintText: "Add a caption...",
                            hintStyle: TextStyle(color: Colors.deepPurple),
                            border: InputBorder.none),
                      ),
                    ),
                  ),
                ),
                if(isSending)
                  Container(
                      width: mq.width,
                      height: mq.height,
                      alignment: Alignment.center,
                      color: Colors.black38,
                      child: CircularProgressIndicator()),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: MaterialButton(
                    onPressed: () async {
                      setState(() {
                        isSending = true;
                      });
                      await sendStatus(context);
                      setState(() {
                        isSending = false;
                      });
                      Navigator.pop(context);
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
          )),
        ],
      )),
    );
  }
}
