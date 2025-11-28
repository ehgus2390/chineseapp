import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
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
    final myUid = context.read<AuthProvider>().currentUser?.uid;

    if (myUid == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.lock_outline, size: 42, color: Colors.grey),
            SizedBox(height: 12),
            Text('로그인이 필요합니다.', textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchProfile(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final photoUrl = data?['photoUrl'] as String?;
        final bio = data?['bio'] as String?;
        final display = data?['displayName'] as String? ?? displayName ?? '익명 사용자';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: snapshot.connectionState == ConnectionState.waiting
              ? const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: (photoUrl != null && photoUrl.startsWith('http'))
                          ? NetworkImage(photoUrl)
                          : const AssetImage('assets/images/logo.png') as ImageProvider,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      display,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (bio != null && bio.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (uid != myUid)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // 팝업 닫기
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatRoomScreen(
                                peerId: uid,
                                peerName: display,
                                peerPhoto: photoUrl,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text("대화 시작하기"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
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
