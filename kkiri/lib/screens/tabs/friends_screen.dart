import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/friends_provider.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final friendsProv = context.watch<FriendsProvider>();

    final myUid = auth.currentUser?.uid;
    if (myUid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: friendsProv.myFriendsStream(myUid),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final friends = snap.data ?? const <Map<String, dynamic>>[];
          if (friends.isEmpty) {
            return const Center(child: Text('친구가 없습니다.'));
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (_, i) {
              final f = friends[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: f['photoUrl'] != null
                      ? NetworkImage(f['photoUrl'])
                      : null,
                  child: f['photoUrl'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(f['displayName'] ?? '익명'),
                subtitle: Text('@${f['searchId'] ?? ''}'),
                trailing: const Icon(Icons.favorite, color: Colors.pink),
              );
            },
          );
        },
      ),
    );
  }
}
