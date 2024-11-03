import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:our_chat/Constants/alerts.dart';
import 'package:our_chat/Database/notes_db.dart';
import 'package:our_chat/Screens/Notepad/add_note.dart';
import 'package:our_chat/Screens/Notepad/read_note.dart';
import 'package:our_chat/Widgets/Notepad/note_list.dart';
import 'package:our_chat/Widgets/open_item.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '../../Models/note_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<NotesDB>().getNotes();
    List<Note> notes = context.watch<NotesDB>().allNotes;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "Notepad",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                confirmDelete(context: context, content: "All the notes saved will be cleared and deleted permanently!", delete: (){
                  context.read<NotesDB>().clearNotes();
                  Navigator.pop(context);
                });
              },
              icon: const Icon(CupertinoIcons.delete))
        ],
      ),
      body: ListView.builder(
        reverse: true,
        shrinkWrap: true,
        itemCount: notes.length,
        itemBuilder: (context, index) {
          Note note = notes[index];
          return Padding(
            padding: const EdgeInsets.all(18.0),
            child: OpenItem(
              closedChild: NoteList(note: note),
              openChild: ReadNote(id: note.id!),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          Navigator.push(
              context,
              PageTransition(
                  child: const AddNote(),
                  type: PageTransitionType.bottomToTop));
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
