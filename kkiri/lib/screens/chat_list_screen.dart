import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.matches.isEmpty) {
      return const Center(child: Text('채팅할 매칭이 없어요'));
    }
    return ListView(
      children: state.matches.map((m) {
        final partner = state.getById(m.partnerId);
        return ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(partner.avatarUrl)),
          title: Text(partner.name),
          subtitle: Text('새로운 대화를 시작해보세요'),
          onTap: () => Navigator.pushNamed(context, '/home/chat/room/${m.id}'),
        );
      }).toList(),
    );
  }
}
