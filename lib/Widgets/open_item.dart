import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

class OpenItem extends StatelessWidget {
  final Widget openChild;
  final Widget closedChild;
  const OpenItem({super.key, required this.openChild, required this.closedChild});

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      closedColor: Colors.transparent,
      openColor: Colors.transparent,
      closedElevation: 0,
      openElevation: 0,
      closedBuilder: (context, action) => closedChild, openBuilder: (context, action) => openChild,);
  }
}
