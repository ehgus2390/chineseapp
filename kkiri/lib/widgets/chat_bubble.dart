import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String? photoUrl;
  final String time;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.photoUrl,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(16);
    final url = photoUrl;
    final hasUrl = url != null && url.startsWith('http');

    return Row(
      mainAxisAlignment:
      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe)
          CircleAvatar(
            radius: 16,
            backgroundImage: hasUrl
                ? NetworkImage(url)
                : const AssetImage('assets/images/logo.png') as ImageProvider,
          ),
        const SizedBox(width: 6),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isMe ? Colors.blueAccent : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: radius,
                topRight: radius,
                bottomLeft: isMe ? radius : Radius.zero,
                bottomRight: isMe ? Radius.zero : radius,
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          time,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}
