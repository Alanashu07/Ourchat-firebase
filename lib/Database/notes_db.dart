import 'package:flutter/widgets.dart';
import 'package:our_chat/Models/note_model.dart';
import 'package:sqflite/sqflite.dart';

late Database notesDB;

class NotesDB extends ChangeNotifier {
  static List<Note> notes = [];

  List<Note> get allNotes => notes;

  static Future<void> initDB() async {
    notesDB = await openDatabase('notes.db', version: 1, onCreate: (db, version) async {
      await db.execute('CREATE TABLE Notes (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT, time TEXT)');
    },);
  }

  void addNote(Note note) async {
    await notesDB.rawInsert('INSERT INTO Notes (title, content, time) VALUES ("${note.title}", "${note.content}", "${note.time}")');
    getNotes();
  }

  void getNotes() async {
    final fetchedNotes = await notesDB.rawQuery('SELECT * FROM Notes');
    notes = fetchedNotes.map((e) => Note.fromJson(e)).toList();
    notifyListeners();
  }

  void clearNotes() async {
    for(var note in notes) {
      await notesDB.rawDelete('DELETE FROM Notes WHERE id = ${note.id}');
    }
    getNotes();
  }

  void deleteNote(int id) async {
    notesDB.rawDelete('DELETE FROM Notes WHERE id = $id');
    notes.removeWhere((note) => note.id == id);
    notifyListeners();
  }

  void updateNote(
      {required Note note,
        required String title,
        required String content}) async {
    notesDB.rawUpdate('UPDATE Notes SET title = "$title", content = "$content" WHERE id = ${note.id}');
    note.title = title;
    note.content = content;
    notifyListeners();
  }
}