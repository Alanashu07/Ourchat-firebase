import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:our_chat/Screens/OurChat/chatting_screen.dart';
import 'package:our_chat/Services/auth_services.dart';
import 'package:our_chat/Services/message_services.dart';
import 'package:our_chat/Widgets/Notepad/custom_text_field.dart';
import 'package:our_chat/Widgets/OurChat/user_tile.dart';
import 'package:our_chat/Widgets/open_item.dart';
import '../../../Constants/alerts.dart';
import '../../../Models/message_model.dart';
import '../../../Models/user_model.dart';

class ChatHome extends StatefulWidget {
  const ChatHome({super.key});

  @override
  State<ChatHome> createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome> {
  List<User> users = [];
  List<String> selectedUsers = [];
  bool selectionMode = false;

  List<String>? initialUsers;

  @override
  void initState() {
    getInitialUsers();
    super.initState();
  }

  getInitialUsers() async {
    final data = await AuthServices.firestore
        .collection(AuthServices.usersCollection)
        .doc(AuthServices.currentUser.id)
        .collection('my_users')
        .get();
    initialUsers = data.docs.map((e) => e.id).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    return Scaffold(
      body: initialUsers == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : initialUsers!.isEmpty
              ? Center(
                  child: Container(
                    height: mq.height * .5,
                    width: mq.width,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.chat_bubble_text,
                          color: Colors.deepPurple,
                          size: mq.width * .1,
                        ),
                        const Text(
                          "No Chatting yet!",
                          style:
                              TextStyle(color: Colors.deepPurple, fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                )
              : StreamBuilder(
                  stream: AuthServices.getMyUserId(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: Container(
                          height: mq.height * .5,
                          width: mq.width,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.chat_bubble_text,
                                color: Colors.deepPurple,
                                size: mq.width * .1,
                              ),
                              const Text(
                                "No Chatting yet!",
                                style: TextStyle(
                                    color: Colors.deepPurple, fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text(snapshot.error.toString());
                    }
                    return StreamBuilder(
                      stream: AuthServices.getAllUsersFromFB(
                          snapshot.data?.docs.map((e) => e.id).toList() ?? []),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(snapshot.error.toString());
                        }
                        final data = snapshot.data?.docs;
                        users = data
                                ?.map((e) => User.fromJson(e.data()))
                                .toList() ??
                            [];
                        users.sort((a, b) => b.lastActive.compareTo(a.lastActive),);

                        return ListView.builder(
                            itemBuilder: (context, index) {
                              final user = users[index];
                              bool selected = selectedUsers.contains(user.id);
                              return GestureDetector(
                                onLongPress: () {
                                  setState(() {
                                    selectionMode = true;
                                    selectedUsers.add(user.id);
                                  });
                                },
                                child: selectionMode
                                    ? GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (selectedUsers
                                                .contains(user.id)) {
                                              selectedUsers.remove(user.id);
                                              if(selectedUsers.isEmpty){
                                                selectionMode = false;
                                              }
                                            } else {
                                              selectedUsers.add(user.id);
                                            }
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                            color: selected ? Colors.blue.shade100 : null,
                                            child: UserTile(
                                                color: selected
                                                    ? Colors.blue
                                                    : Colors.deepPurple,
                                                user: user),
                                          ),
                                        ),
                                      )
                                    : OpenItem(
                                        openChild: ChattingScreen(
                                            user: AuthServices.currentUser,
                                            chatUser: user),
                                        closedChild: Padding(
                                          padding: const EdgeInsets.all(18.0),
                                          child: UserTile(
                                              color: Colors.deepPurple,
                                              user: user),
                                        )),
                              );
                            },
                            itemCount: users.length);
                      },
                    );
                  },
                ),
      floatingActionButton: selectionMode
          ? SpeedDial(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              foregroundColor: Colors.white,
              child: Icon(Icons.more_vert),
              children: [
                if(selectedUsers.isNotEmpty)
                SpeedDialChild(
                  onTap: () {
                    confirmDelete(
                        context: context,
                        content: "Selected Users will be deleted!",
                        delete: () async {
                          Navigator.pop(context);
                          for(var user in selectedUsers) {
                            await AuthServices.firestore
                                .collection(AuthServices.usersCollection)
                                .doc(AuthServices.currentUser.id)
                                .collection('my_users')
                                .doc(user)
                                .delete();
                          }
                          setState(() {
                            selectionMode = false;
                            selectedUsers.clear();
                          });
                        });
                  },
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: const Icon(
                    CupertinoIcons.delete,
                    color: Colors.white,
                  ),
                ),
                SpeedDialChild(
                  onTap: () {
                    setState(() {
                      selectionMode = false;
                      selectedUsers.clear();
                    });
                  },
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                )
              ],
            )
          : FloatingActionButton(
              onPressed: () {
                TextEditingController controller = TextEditingController();
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Add new user"),
                      content: CustomTextField(
                          controller: controller,
                          textInputType: TextInputType.emailAddress,
                          textCapitalization: TextCapitalization.none),
                      actions: [
                        TextButton(
                            onPressed: () async {
                              try {
                                if (controller.text.trim().isNotEmpty) {
                                  if (controller.text.trim() ==
                                      AuthServices.currentUser.email) {
                                    showAlert(
                                        context: context,
                                        title: "Invalid",
                                        content: "You cannot add yourself");
                                  } else if ((await AuthServices.firestore
                                          .collection(
                                              AuthServices.usersCollection)
                                          .doc(AuthServices.currentUser.id)
                                          .collection('my_users')
                                          .doc(AuthServices.users
                                              .firstWhere((element) =>
                                                  element.email ==
                                                  controller.text.trim())
                                              .id)
                                          .get())
                                      .exists) {
                                    showAlert(
                                        context: context,
                                        title: "User Exists",
                                        content:
                                            "User with email ${controller.text} already exists.");
                                  } else {
                                    final newUser =
                                        AuthServices.users.firstWhere(
                                      (element) =>
                                          element.email ==
                                          controller.text.trim(),
                                    );
                                    AuthServices.addNewUser(user: newUser)
                                        .then((value) => setState(() {}));
                                    // setState(() {});
                                    Navigator.pop(context);
                                  }
                                }
                                if (controller.text.trim().isEmpty) {
                                  showAlert(
                                      context: context,
                                      title: "Email empty",
                                      content:
                                          "Please add some email to add a user.");
                                }
                              } catch (e) {
                                showAlert(
                                    context: context,
                                    title: "User Not Found",
                                    content:
                                        "User with email ${controller.text} not found");
                              }
                            },
                            child: const Text("Add")),
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Cancel")),
                      ],
                    );
                  },
                );
              },
              backgroundColor: Colors.deepPurple,
              child: const Icon(
                CupertinoIcons.chat_bubble_2,
                color: Colors.white,
              ),
            ),
    );
  }
}
