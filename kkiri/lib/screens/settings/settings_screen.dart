import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(title: Text('프로필 사진 변경'), trailing: Icon(Icons.chevron_right)),
        ListTile(title: Text('알림 설정'), trailing: Icon(Icons.chevron_right)),
        ListTile(title: Text('언어 설정'), trailing: Icon(Icons.chevron_right)),
        ListTile(title: Text('고객센터'), trailing: Icon(Icons.chevron_right)),
      ],
    );
  }
}
