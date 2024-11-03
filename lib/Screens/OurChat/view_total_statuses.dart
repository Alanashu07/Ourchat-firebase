import 'package:flutter/material.dart';
import 'package:our_chat/Widgets/OurChat/total_status_list.dart';
import 'package:provider/provider.dart';
import '../../Services/auth_services.dart';

class ViewTotalStatuses extends StatelessWidget {
  const ViewTotalStatuses({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthServices>(context).user;
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Status"),
      ),
      body: ListView.separated(
          itemCount: user.status.length,
          itemBuilder: (context, index) {
            return TotalStatusList(index: index,);
          }, separatorBuilder: (context, index) => const Divider(color: Colors.black54,),),
    );
  }
}
