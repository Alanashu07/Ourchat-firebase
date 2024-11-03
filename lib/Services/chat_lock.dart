import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatLock extends ChangeNotifier{

  static String? chatLock;

  static String? chatWallpaper;

  String? get wallpaper => chatWallpaper;

  String? get lock => chatLock;

  static late SharedPreferences prefs;

  static Future<void> initPreference() async {
    prefs = await SharedPreferences.getInstance();
  }
  Future<void> setLock(String value) async {
    await prefs.setString('lock', value);
    chatLock = value;
    notifyListeners();
  }

  Future<void> setWallpaper(XFile image) async {
    await prefs.setString('wallpaper', image.path);
    chatWallpaper = image.path;
    notifyListeners();
  }

  static void getWallpaper() {
    chatWallpaper = prefs.getString('wallpaper');
  }

  void clearWallpaper() async {
    await prefs.remove('wallpaper');
    chatWallpaper = null;
    notifyListeners();
  }

  void clearLock() async {
    await prefs.remove('lock');
    notifyListeners();
  }
  void getLock() {
    chatLock = prefs.getString('lock');
    notifyListeners();
  }

  static void getCurrentLock() {
    chatLock = prefs.getString('lock');
  }
}