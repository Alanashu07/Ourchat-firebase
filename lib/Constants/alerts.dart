import 'package:flutter/material.dart';

void showAlert(
    {required BuildContext context,
    required String title,
    required String content}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}

void confirmDelete({required BuildContext context, required String content, required VoidCallback delete}) {
  showDialog(context: context, builder: (context) {
    return AlertDialog(
      title: const Text("Are you sure?"),
      content: Text(content),
      actions: [
        TextButton(onPressed: delete, child: const Text("Delete")),
        TextButton(onPressed: (){
          Navigator.pop(context);
        }, child: const Text("Cancel")),
      ],
    );
  },);
}

void showSnackBar(
    {required BuildContext context, required String content, Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(content),
    backgroundColor: color,
  ));
}
