import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friends_provider.dart';
import '../chat/chat_room_screen.dart'; // 🔹 채팅방 화면 import

class UserProfilePopup extends StatelessWidget {
  final String uid;
  final String? displayName;
  final String? photoUrl;

  const UserProfilePopup({
    super.key,
    required this.uid,
    this.displayName,
    this.photoUrl,
  });

  /// Firestore에서 사용자 상세 프로필 가져오기
  Future<Map<String, dynamic>?> _fetchProfile() async {
    final snap =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return snap.data();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = context.read<AuthProvider>().currentUser!.uid;
    final friends = context.read<FriendsProvider>();

    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchProfile(),
      builder: (context, snapshot) {
        final data = snapshot.data;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: snapshot.connectionState == ConnectionState.waiting
              ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()))
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 45,
                backgroundImage: (data?['photoUrl'] != null &&
                    data!['photoUrl'].toString().startsWith('http'))
                    ? NetworkImage(data['photoUrl'])
                    : const AssetImage('assets/images/logo.png')
                as ImageProvider,
              ),
              const SizedBox(height: 12),
              Text(
                data?['displayName'] ?? displayName ?? '익명 사용자',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (data?['bio'] != null) ...[
                const SizedBox(height: 6),
                Text(
                  data!['bio'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
              const SizedBox(height: 16),
              if (uid != myUid) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await friends.sendLike(myUid, uid);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('좋아요를 보냈습니다.')),
                            );
                          }
                        },
                        icon: const Icon(Icons.favorite_border),
                        label: const Text('좋아요'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // 팝업 닫기
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatRoomScreen(
                                peerId: uid,
                                peerName: data?['displayName'] ?? 'Unknown User',
                                peerPhoto: data?['photoUrl'],
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('메시지'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("닫기"),
              ),
            ],
          ),
        );
      },
    );
  }
}
