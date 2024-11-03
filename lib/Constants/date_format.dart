import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DateFormat{
  static String getFormattedTime({required BuildContext context, required String time}) {
    final date = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    return TimeOfDay.fromDateTime(date).format(context);
  }

  static String getDate({required BuildContext context, required String date}) {
    final DateTime pickedDate = DateTime.fromMillisecondsSinceEpoch(int.parse(date));
    return '${pickedDate.day} ${_getMonth(pickedDate)} ${pickedDate.year}';
  }

  static String getMessageDay({required BuildContext context, required String date}) {
    final now = DateTime.now();
    final day = DateTime.fromMillisecondsSinceEpoch(int.parse(date));
    if(now.day == day.day && now.month == day.month && now.year == day.year) {
      return 'Today';
    } else if(now.subtract(1.days).day == day.day && now.month == day.month && now.year == day.year) {
      return 'Yesterday';
    } else if(now.year == day.year) {
      return '${day.day} ${_getMonth(day)}';
    } else {
      return '${day.day} ${_getMonth(day)} ${day.year}';
    }
  }

  static String getNow() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static String getLastActiveTime({
    required BuildContext context, required String lastActive
  }){
    final int i = int.tryParse(lastActive) ?? -1;
    if(i == -1) return 'Last Seen Not Available';

    DateTime time = DateTime.fromMillisecondsSinceEpoch(i);
    DateTime now = DateTime.now();

    String formattedTime = TimeOfDay.fromDateTime(time).format(context);
    if(time.day == now.day && time.month == now.month && time.year == now.year) {
      return 'Last seen today at $formattedTime';
    }
    if((now.difference(time).inHours / 24).round() <= 1) {
      return 'Last seen yesterday at $formattedTime';
    }
    String month = _getMonth(time);
    return 'Last seen on ${time.day} $month on $formattedTime';
  }

  static String getMessageTime({required BuildContext context, required String time}){
    final DateTime sent = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    final DateTime now = DateTime.now();

    final formattedTime = TimeOfDay.fromDateTime(sent).format(context);
    if(now.day == sent.day && now.month == sent.month && now.year == sent.year) {
      return formattedTime;
    }
    return now.year == sent.year ? '$formattedTime - ${sent.day} ${_getMonth(sent)}' : '$formattedTime - ${sent.day} ${_getMonth(sent)} ${sent.year}';
  }

  static String getTimeAgo(String dateTime) {
    DateTime time = DateTime.fromMillisecondsSinceEpoch(int.parse(dateTime));
    final now = DateTime.now();
    int difference = now.difference(time).inSeconds;
    if(difference < 60) {
      return '$difference seconds ago';
    } else if(difference < 3600) {
      return '${(difference / 60).round()} minutes ago';
    } else if(difference < 86400) {
      return '${(difference / 3600).round()} hours ago';
    } else {
      return '${(difference / 86400).round()} days ago';
    }
  }

  static String
  getCreatedTime({required BuildContext context, required String time}) {
    final DateTime created = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    final DateTime now = DateTime.now();

    if(now.day == created.day && now.month == created.month && now.year == created.year) {
      return TimeOfDay.fromDateTime(created).format(context);
    }
    bool showYear = now.year != created.year;
    return showYear ? '${created.day} ${_getMonth(created)} ${created.year}' : '${created.day} ${_getMonth(created)}';
  }
  static String _getMonth(DateTime date) {
    switch(date.month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
    }
    return 'NA';
  }

  static String getAge({required BuildContext context, required String dob}) {
    final DateTime birth = DateTime.fromMillisecondsSinceEpoch(int.parse(dob));
    final now = DateTime.now();
    int years =  now.year - birth.year;
    int months = now.month - birth.month;

    if(months < 0 || (months == 0 && now.day < birth.day)) {
      years--;
      months+=12;
    }

    if(now.day < birth.day) {
      months --;
    }
    if(years == 0 && months == 1) {
      return '1 Month';
    }
    else if(years == 0 && months > 1) {
      return '$months Months';
    }
    else if(years == 1 && months == 0) {
      return '1 Year';
    }
    else if(years == 1 && months == 1) {
      return '1 Year and 1 Month';
    }
    else if(years == 1 && months < 1) {
      return '1 Year and $months Months';
    }
    else if(years > 1 && months == 0) {
      return '$years Years';
    }
    else if(years > 1 && months == 1) {
      return '$years Years and 1 Month';
    }
    else{
      return '$years Years and $months Months';
    }
  }
}