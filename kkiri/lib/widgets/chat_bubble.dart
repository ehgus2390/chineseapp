import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final bool isMe;
  final String? text;
  final String? imageUrl;
  final DateTime? time;
  final String? avatarUrl; // 좌측 아바타(상대방만 표시)

  const ChatBubble({
    super.key,
    required this.isMe,
    this.text,
    this.imageUrl,
    this.time,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? Colors.lightBlue[100] : Colors.grey[200];
    final timeStr = time != null ? DateFormat('a h:mm').format(time!) : '';

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
      padding: imageUrl != null ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: imageUrl != null ? null : bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
          bottomRight: isMe ? Radius.zero : const Radius.circular(12),
        ),
      ),
      child: imageUrl != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(imageUrl!, fit: BoxFit.cover),
      )
          : Text(text ?? '', style: const TextStyle(fontSize: 15)),
    );

    final content = Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe)
          CircleAvatar(
            radius: 15,
            backgroundImage: (avatarUrl != null && avatarUrl!.startsWith('http')) ? NetworkImage(avatarUrl!) : null,
            child: (avatarUrl == null) ? const Icon(Icons.person, size: 15) : null,
          ),
        if (!isMe) const SizedBox(width: 6),
        Flexible(child: bubble),
        const SizedBox(width: 4),
        Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: content,
      ),
    );
  }
}
