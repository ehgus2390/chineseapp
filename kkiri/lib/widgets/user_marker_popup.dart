import 'package:flutter/material.dart';

class UserMarkerPopup extends StatelessWidget {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final VoidCallback onChatPressed;

  const UserMarkerPopup({
    super.key,
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.onChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 220,
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null ? const Icon(Icons.person, size: 40) : null,
          ),
          const SizedBox(height: 10),
          Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onChatPressed,
            icon: const Icon(Icons.chat),
            label: const Text("대화 시작"),
          ),
        ],
      ),
    );
  }
}
