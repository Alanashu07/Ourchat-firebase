import 'package:flutter/material.dart';
import 'package:our_chat/Constants/alerts.dart';
import 'package:our_chat/Constants/date_format.dart';
import 'package:our_chat/Models/note_model.dart';
import 'package:our_chat/Screens/Notepad/home_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

import '../../Database/notes_db.dart';

class AddNote extends StatefulWidget {
  final Note? note;

  const AddNote({super.key, this.note});

  @override
  State<AddNote> createState() => _AddNoteState();
}

class _AddNoteState extends State<AddNote> {
  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (widget.note != null) {
      titleController.text = widget.note!.title;
      contentController.text = widget.note!.content;
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        if (titleController.text.trim().isNotEmpty ||
            contentController.text.trim().isNotEmpty) {
          if (widget.note == null) {
            Navigator.pop(context);
            Note note = Note(
                title: titleController.text.trim(),
                content: contentController.text.trim(),
                time: DateFormat.getNow());
            context.read<NotesDB>().addNote(note);
          } else {
            context.read<NotesDB>().updateNote(
                note: widget.note!,
                title: titleController.text.trim(),
                content: contentController.text.trim());
            Navigator.pop(context);
          }
        }
        if (titleController.text.trim().isEmpty &&
            contentController.text.trim().isEmpty) {
          if (widget.note != null) {
            context.read<NotesDB>().deleteNote(widget.note!.id!);
          }
          Navigator.pushAndRemoveUntil(
            context,
            PageTransition(
                child: HomeScreen(), type: PageTransitionType.rightToLeft),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: widget.note == null
              ? const Text("Add new note")
              : Text(
                  "Edit note ${widget.note!.title}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  controller: titleController,
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 22),
                  textCapitalization: TextCapitalization.sentences,
                  autofocus: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter title here',
                    hintStyle: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                        fontSize: 22),
                  ),
                ),
                TextFormField(
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  controller: contentController,
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.normal,
                      fontSize: 18),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter content here',
                    hintStyle: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.normal,
                        fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepPurple,
          onPressed: () {
            if (titleController.text.trim().isNotEmpty ||
                contentController.text.trim().isNotEmpty) {
              if (widget.note == null) {
                Navigator.pop(context);
                Note note = Note(
                    title: titleController.text.trim(),
                    content: contentController.text.trim(),
                    time: DateFormat.getNow());
                context.read<NotesDB>().addNote(note);
              } else {
                context.read<NotesDB>().updateNote(
                    note: widget.note!,
                    title: titleController.text.trim(),
                    content: contentController.text.trim());
                Navigator.pop(context);
              }
            } else {
              showAlert(
                  context: context,
                  title: "Empty note!!",
                  content:
                      "You cannot save an empty note. Please add something");
            }
          },
          child: const Icon(
            Icons.save,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
