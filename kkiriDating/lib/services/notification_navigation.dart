import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

Future<void> handleNotificationNavigation(
  BuildContext context,
  Map<String, dynamic> data,
) async {
  final type = data['type']?.toString();
  if (type == null) {
    _navigateSafely(context, '/home/chat');
    return;
  }

  String? targetRoute;
  if (type == 'match_accepted') {
    final chatRoomId = data['chatRoomId']?.toString();
    if (chatRoomId == null || chatRoomId.isEmpty) {
      _navigateSafely(context, '/home/chat');
      return;
    }
    targetRoute = '/home/chat/room/$chatRoomId';
  } else if (type == 'new_message') {
    final roomId = data['roomId']?.toString();
    if (roomId == null || roomId.isEmpty) {
      _navigateSafely(context, '/home/chat');
      return;
    }
    targetRoute = '/home/chat/room/$roomId';
  }

  if (targetRoute == null) {
    _navigateSafely(context, '/home/chat');
    return;
  }
  _navigateSafely(context, targetRoute);
}

void _navigateSafely(BuildContext context, String targetRoute) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    GoRouter.of(context).go(targetRoute);
  });
}
