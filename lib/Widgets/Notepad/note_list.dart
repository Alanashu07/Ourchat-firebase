import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:our_chat/Constants/alerts.dart';
import 'package:our_chat/Models/note_model.dart';
import 'package:our_chat/Screens/Notepad/add_note.dart';
import 'package:our_chat/Widgets/open_item.dart';
import 'package:provider/provider.dart';
import '../../Database/notes_db.dart';

class NoteList extends StatelessWidget {
  final Note note;

  const NoteList({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 100,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), color: Colors.deepPurple),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  note.content,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
          OpenItem(
              openChild: AddNote(
                note: note,
              ),
              closedChild: const Icon(
                Icons.edit,
                color: Colors.white,
              )),
          const SizedBox(width: 10,),
          IconButton(
              onPressed: () {
                confirmDelete(
                    context: context,
                    content:
                        "Your note ${note.title} will be deleted Permanently!",
                    delete: () {
                      Navigator.pop(context);
                      if (note.id != null) {
                        context.read<NotesDB>().deleteNote(note.id!);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Unable to delete note")),
                        );
                      }
                    });
              },
              icon: const Icon(
                CupertinoIcons.delete,
                color: Colors.white,
              )),
        ],
      ),
    );
  }
}
