import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:our_chat/Constants/date_format.dart';

import '../Constants/alerts.dart';

class ImageViewer extends StatelessWidget {
  final String title;
  final String image;

  const ImageViewer({super.key, required this.title, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.4),
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(CupertinoIcons.back, color: Colors.white)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              try {
                // Fetch the file
                final response = await http.get(Uri.parse(image));

                if (response.statusCode == 200) {
                  // Get the external storage directory
                  Directory? externalDir =
                      Directory('/storage/emulated/0/Download/Notepad/Images');
                  if (!await externalDir.exists()) {
                    await externalDir.create(recursive: true);
                  }
                  String filePath = '';
                  filePath =
                      '${externalDir.path}/Image-${DateFormat.getNow()}.jpg';
                  // if(Platform.isAndroid) {
                  //   filePath = '/storage/emulated/0/Download/Notepad/$fileName';
                  // }
                  // else{
                  //   filePath = '${externalDir!.path}/$fileName';
                  // }

                  // Save the file
                  File file = File(filePath);
                  await file.writeAsBytes(response.bodyBytes);

                  // Notify the media scanner to add the file to the gallery
                  Process.run('am', [
                    'broadcast',
                    '-a',
                    'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
                    '-d',
                    'file://$filePath'
                  ]);

                  showSnackBar(
                      context: context,
                      content: 'File saved to gallery',
                      color: Colors.deepPurple);
                  // showAlert(context: context, title: 'File saved', content: 'file saved to $filePath');
                } else {
                  showAlert(
                      context: context,
                      title: 'Failed to fetch',
                      content: 'Failed to fetch file: ${response.statusCode}');
                }
              } catch (e) {
                showAlert(
                    context: context,
                    title: "Error saving",
                    content: 'Error saving file $e');
              }
            },
            icon: Icon(Icons.download, color: Colors.white),
          )
        ],
      ),
      body: Center(
          child: InteractiveViewer(
        maxScale: 10,
        minScale: 0.5,
        clipBehavior: Clip.none,
        child: CachedNetworkImage(
          imageUrl: image,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => Icon(Icons.error),
        ),
      )),
    );
  }
}
