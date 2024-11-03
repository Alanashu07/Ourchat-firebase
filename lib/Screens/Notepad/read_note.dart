import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:our_chat/Constants/alerts.dart';
import 'package:our_chat/Database/notes_db.dart';
import 'package:our_chat/Screens/Notepad/add_note.dart';
import 'package:our_chat/Screens/OurChat/lock_screen.dart';
import 'package:our_chat/Widgets/open_item.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '../../Constants/date_format.dart';

class ReadNote extends StatelessWidget {
  final int id;

  const ReadNote({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final note = context.watch<NotesDB>().allNotes.firstWhere(
          (element) => element.id == id,
        );
    return Scaffold(
      appBar: AppBar(
        title: const Text("Note View"),
        actions: [
          OpenItem(
              openChild: AddNote(
                note: note,
              ),
              closedChild: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.edit),
              )),
          GestureDetector(
            onLongPress: () {
              confirmDelete(context: context, content: "Your note ${note.title} will be deleted permanently!!", delete: (){
                Navigator.pop(context);
                Navigator.push(context, PageTransition(child: const LockScreen(), type: PageTransitionType.rightToLeft));
              });
            },
            child: IconButton(
                onPressed: () {
                  confirmDelete(context: context, content: "Your note ${note.title} will be deleted permanently!!", delete: (){
                    Navigator.pop(context);
                    Navigator.pop(context);
                    context.read<NotesDB>().deleteNote(note.id!);
                  });
                },
                icon: const Icon(CupertinoIcons.delete)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 18,
            ),
            Text(
              note.content,
              style: const TextStyle(fontSize: 18, color: Colors.black38),
            ),
            Row(
              children: [
                const Spacer(),
                Text(
                  DateFormat.getCreatedTime(context: context, time: note.time),
                  style: const TextStyle(fontSize: 12, color: Colors.black38),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
