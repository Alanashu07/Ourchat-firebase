import 'dart:math';
import 'package:flutter/material.dart';

import '../../Models/user_model.dart';

degreeToAngle(double degree) {
  return degree * pi / 180;
}

class StatusPainter extends CustomPainter{
  final User user;
  final Color color;
  StatusPainter({required this.color, required this.user});
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 5
      ..color = color
      ..style = PaintingStyle.stroke;
    drawArc(canvas, size, paint);
  }
  void drawArc(Canvas canvas, Size size, Paint paint) {
    if(user.status.length == 1) {
      canvas.drawArc(Rect.fromLTWH(0.0, 0.0, size.width, size.height), degreeToAngle(0), degreeToAngle(360), false, paint);
    } else {
      double degree = -90;
      double arc = 360 / user.status.length;
      for(int i = 0; i < user.status.length; i++) {
        canvas.drawArc(Rect.fromLTWH(0.0, 0.0, size.width, size.height), degreeToAngle(degree), degreeToAngle(arc - 8), false, paint);
        degree += arc;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}