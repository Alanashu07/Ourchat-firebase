import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:our_chat/Models/user_model.dart';
import 'package:our_chat/Screens/OurChat/chatting_screen.dart';
import 'package:our_chat/Services/auth_services.dart';
import 'package:our_chat/Widgets/OurChat/user_tile.dart';
import 'package:our_chat/Widgets/open_item.dart';
import 'package:provider/provider.dart';

import '../../Widgets/OurChat/search_field.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController controller = TextEditingController();
  List<User> users = [];

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    if (controller.text.trim().isNotEmpty) {
      users = context
          .watch<AuthServices>()
          .allUsers
          .where((user) =>
              user.name
                  .toLowerCase()
                  .contains(controller.text.trim().toLowerCase()) ||
              user.email
                  .toLowerCase()
                  .contains(controller.text.trim().toLowerCase()) ||
              user.about
                  .toLowerCase()
                  .contains(controller.text.trim().toLowerCase()))
          .toList();
      users = users.toSet().toList();
    } else {
      users = [];
    }
    return Container(
      color: Colors.white,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 100,
          title: SearchField(
            controller: controller,
            isSearchScreen: true,
            onChanged: (value) {
              setState(() {
                controller.text = value;
              });
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding:
                EdgeInsets.symmetric(vertical: mq.height * .05, horizontal: 18),
            child: ListView.separated(
              itemCount: users.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return OpenItem(
                  openChild: ChattingScreen(
                      user: context.watch<AuthServices>().user,
                      chatUser: users[index]),
                  closedChild:
                      UserTile(color: Colors.deepPurple, user: users[index]),
                ).animate().slideY(begin: 1, end: 0, duration: 200.ms).fade();
              },
              separatorBuilder: (context, index) => SizedBox(
                height: mq.height * .03,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
