import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:our_chat/Database/notes_db.dart';
import 'package:our_chat/Screens/Notepad/home_screen.dart';
import 'package:our_chat/Services/auth_services.dart';
import 'package:our_chat/Services/chat_lock.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ChatLock.initPreference();
  await NotesDB.initDB();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NotesDB(),),
        ChangeNotifierProvider(create: (context) => ChatLock(),),
        ChangeNotifierProvider(create: (context) => AuthServices(),),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Notepad',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        // home: const LoginScreen(),
      ),
    );
  }
}
