import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_localizations.dart';
import '../models/chat_thread.dart';
import '../models/comment.dart';
import '../models/message.dart';
import '../models/post.dart';
import '../models/profile.dart';
import '../services/chat_service.dart';
import '../services/preferences_storage.dart';

enum AddFriendResult { added, already, notFound }

class AppState extends ChangeNotifier {
  AppState();

  final ChatService chat = ChatService();
  final PreferencesStorage _preferences = PreferencesStorage.instance;

  final Map<String, Profile> _profiles = <String, Profile>{};
  final Map<String, Profile> _directory = <String, Profile>{};
  final List<Profile> _friends = <Profile>[];
  final Map<String, ChatThread> _threads = <String, ChatThread>{};
  final List<Post> _posts = <Post>[];
  final Distance _distance = Distance();
  final Map<String, bool> _notificationOptions = <String, bool>{
    'notificationMessages': true,
    'notificationFriendRequests': true,
    'notificationCommunityUpdates': true,
  };
  final List<String> _communityInsights = <String>[
    'insightProfileUpdate',
    'insightShareTips',
  ];

  Profile? _me;
  bool _initialized = false;
  final double _nearbyRadiusKm = 5.0;

  Profile get me => _me!;
  List<Profile> get friends => List<Profile>.unmodifiable(_friends);
  List<Profile> get nearbyProfiles {
    final List<Profile> list = _profiles.values
        .where((Profile p) =>
            p.id != me.id &&
            _distance(
                  LatLng(me.latitude, me.longitude),
                  LatLng(p.latitude, p.longitude),
                ) /
                1000 <=
            _nearbyRadiusKm)
        .toList();
    list.sort((Profile a, Profile b) {
      final double da = _distance(
        LatLng(me.latitude, me.longitude),
        LatLng(a.latitude, a.longitude),
      );
      final double db = _distance(
        LatLng(me.latitude, me.longitude),
        LatLng(b.latitude, b.longitude),
      );
      return da.compareTo(db);
    });
    return List<Profile>.unmodifiable(list);
  }
  double get nearbyRadiusKm => _nearbyRadiusKm;

  List<ChatThread> get threads {
    final list = _threads.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  List<Post> get posts {
    final List<Post> sorted = List<Post>.from(_posts);
    sorted.sort((Post a, Post b) => b.createdAt.compareTo(a.createdAt));
    return UnmodifiableListView<Post>(sorted);
  }

  List<Post> get popularPosts {
    final List<Post> list =
        _posts.where((Post p) => p.likedBy.length >= 3).toList(growable: false);
    list.sort((Post a, Post b) => b.likedBy.length.compareTo(a.likedBy.length));
    return list;
  }

  Map<String, bool> get notificationOptions => Map<String, bool>.unmodifiable(_notificationOptions);
  List<String> get highlightedCommunityInsights =>
      List<String>.unmodifiable(_communityInsights);

  Future<void> bootstrap() async {
    if (_initialized) return;
    _initialized = true;
    _seedMockData();
    await _loadNotificationPreferences();
    notifyListeners();
  }

  void _seedMockData() {
    final Profile meProfile = Profile(
      id: 'minjun',
      name: '민준 Minjun',
      languages: const <String>['ko', 'en'],
      bio: 'Seoul local who loves showing foreigners the best cafés and museums.',
      avatarUrl: 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518',
      statusMessage: 'Let\'s grab coffee and study together ☕️',
      latitude: 37.5665,
      longitude: 126.9780,
    );

    final List<Profile> others = <Profile>[
      Profile(
        id: 'ari',
        name: 'Ari',
        languages: const <String>['ja', 'en'],
        bio: 'Planning a language exchange trip to Korea this spring.',
        avatarUrl: 'https://images.unsplash.com/photo-1544723795-3fb6469f5b39',
        statusMessage: '東京からの韓国語ビギナー 🇯🇵',
        latitude: 37.561, // near Seoul
        longitude: 126.983,
      ),
      Profile(
        id: 'lucas',
        name: 'Lucas',
        languages: const <String>['en', 'es'],
        bio: 'Foodie who wants to practice Korean before visiting Seoul.',
        avatarUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1',
        statusMessage: 'NYC → Seoul for street food!',
        latitude: 37.571,
        longitude: 126.99,
      ),
      Profile(
        id: 'yuna',
        name: 'Yuna',
        languages: const <String>['ko', 'zh'],
        bio: 'Looking for a buddy to explore new cafés and learn Chinese.',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
        statusMessage: '카페 투어 같이 가요 ☕️',
        latitude: 37.559,
        longitude: 126.975,
      ),
      Profile(
        id: 'ananya',
        name: 'Ananya',
        languages: const <String>['hi', 'en'],
        bio: 'Studying K-pop dance and searching for practice partners.',
        avatarUrl: 'https://images.unsplash.com/photo-1544723795-432537c10c1f',
        statusMessage: 'नई कोरियाई दोस्तों की तलाश में 💃',
        latitude: 37.57,
        longitude: 126.97,
      ),
      Profile(
        id: 'liwei',
        name: 'Li Wei',
        languages: const <String>['zh', 'ko'],
        bio: 'Working remotely in Seoul and eager to share Mandarin tips.',
        avatarUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1',
        statusMessage: '서울에서 재택근무 중 🇨🇳',
        latitude: 37.568,
        longitude: 126.965,
      ),
    ];

    _me = meProfile;
    _profiles[meProfile.id] = meProfile;
    _directory[meProfile.id] = meProfile;
    _directory[meProfile.id.toLowerCase()] = meProfile;

    for (final Profile profile in others) {
      _profiles[profile.id] = profile;
      _directory[profile.id] = profile;
      _directory[profile.id.toLowerCase()] = profile;
    }

    _friends
      ..clear()
      ..addAll(<Profile>[others[0], others[1], others[2]]);

    // Create chat threads with sample messages
    for (final Profile friend in _friends) {
      final ChatThread thread = ChatThread(
        id: 'thread_${friend.id}',
        friendId: friend.id,
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        lastMessage: null,
      );
      _threads[thread.id] = thread;

      final Message latest = chat.send(thread.id, friend.id, '안녕! 이번 주말에 시간 있어?');
      thread.lastMessage = latest.text;
      thread.updatedAt = latest.createdAt;
      final Message reply =
          chat.send(thread.id, me.id, 'Hi ${friend.name.split(' ').first}! Let\'s plan something.');
      thread.lastMessage = reply.text;
      thread.updatedAt = reply.createdAt;
    }

    _posts
      ..clear()
      ..addAll(<Post>[
        Post(
          id: 'p1',
          authorId: 'ari',
          content: 'Any recommendations for a cozy study café near City Hall? 😊',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          likedBy: <String>{'lucas', 'yuna', 'minjun'},
          comments: <Comment>[
            Comment(
              id: 'c1',
              postId: 'p1',
              authorId: 'yuna',
              text: 'Try Onion Café! Their rooftop is beautiful.',
              createdAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 30)),
            ),
          ],
        ),
        Post(
          id: 'p2',
          authorId: 'minjun',
          content: 'We are organizing a hanbok photo walk this Saturday. DM me if you want to join!',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          likedBy: <String>{'ari', 'lucas', 'yuna', 'liwei'},
        ),
        Post(
          id: 'p3',
          authorId: 'lucas',
          content: 'Found a great tteokbokki place near Hongdae. Who wants to go together tonight?',
          createdAt: DateTime.now().subtract(const Duration(minutes: 50)),
          likedBy: <String>{'minjun', 'ari'},
        ),
      ]);
  }

  Profile getById(String id) {
    final Profile? profile = _directory[id] ?? _directory[id.toLowerCase()];
    if (profile == null) {
      throw StateError('Profile $id not found');
    }
    return profile;
  }

  ChatThread threadById(String id) {
    final ChatThread? thread = _threads[id];
    if (thread == null) {
      throw StateError('Thread $id not found');
    }
    return thread;
  }

  String ensureThread(String friendId) {
    final Profile friend = getById(friendId);
    final String threadId = 'thread_${friend.id}';
    return _threads.putIfAbsent(
      threadId,
      () => ChatThread(id: threadId, friendId: friend.id, updatedAt: DateTime.now()),
    ).id;
  }

  void sendMessage(String threadId, String text) {
    if (text.isEmpty) return;
    final Message message = chat.send(threadId, me.id, text);
    final ChatThread thread = threadById(threadId);
    thread.lastMessage = message.text;
    thread.updatedAt = message.createdAt;
    notifyListeners();
  }

  String formatTime(DateTime time) {
    final TimeOfDay tod = TimeOfDay.fromDateTime(time);
    return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
  }

  String formatDistance(Profile profile) {
    final double meters = _distance(
      LatLng(me.latitude, me.longitude),
      LatLng(profile.latitude, profile.longitude),
    );
    final double km = meters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  AddFriendResult addFriendById(String id) {
    final String normalized = id.trim().toLowerCase();
    if (normalized.isEmpty) {
      return AddFriendResult.notFound;
    }

    if (!_directory.containsKey(normalized)) {
      return AddFriendResult.notFound;
    }

    final Profile profile = _directory[normalized]!;
    if (profile.id == me.id) {
      return AddFriendResult.already;
    }
    if (_friends.any((Profile friend) => friend.id == profile.id)) {
      return AddFriendResult.already;
    }

    _friends.add(profile);
    notifyListeners();
    return AddFriendResult.added;
  }

  void updateNotification(String key, bool value) {
    if (!_notificationOptions.containsKey(key)) return;
    _notificationOptions[key] = value;
    _preferences.writeBool('notify_$key', value);
    notifyListeners();
  }

  void addPost(String content) {
    final String trimmed = content.trim();
    if (trimmed.isEmpty) return;
    final Post post = Post(
      id: 'p${_posts.length + 1}',
      authorId: me.id,
      content: trimmed,
      createdAt: DateTime.now(),
    );
    _posts.add(post);
    _communityInsights.insert(0, 'insightNewPost');
    notifyListeners();
  }

  void togglePostLike(String postId) {
    final Post post = _findPost(postId);
    if (post.likedBy.contains(me.id)) {
      post.likedBy.remove(me.id);
    } else {
      post.likedBy.add(me.id);
    }
    notifyListeners();
  }

  void addComment(String postId, String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final Post post = _findPost(postId);
    final Comment comment = Comment(
      id: 'c${post.comments.length + 1}_${post.id}',
      postId: postId,
      authorId: me.id,
      text: trimmed,
      createdAt: DateTime.now(),
    );
    post.comments.add(comment);
    notifyListeners();
  }

  Post _findPost(String postId) {
    final Post? post = _posts.firstWhere((Post p) => p.id == postId, orElse: () => throw StateError('Post not found'));
    return post;
  }

  void updateAvatar(String url) {
    final Profile current = me;
    final Profile updated = current.copyWith(avatarUrl: url);
    _me = updated;
    _profiles[current.id] = updated;
    _directory[current.id] = updated;
    notifyListeners();
  }

  void updateStatus(String newStatus) {
    final Profile current = me;
    final Profile updated = current.copyWith(statusMessage: newStatus);
    _me = updated;
    _profiles[current.id] = updated;
    _directory[current.id] = updated;
    notifyListeners();
  }

  Future<void> handleAddFriendDialog(BuildContext context, AppLocalizations l) async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<AddFriendResult>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l.addFriend),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.addFriendDescription),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(hintText: l.addFriendPlaceholder),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () {
                final AddFriendResult res = addFriendById(controller.text);
                Navigator.of(context).pop(res);
              },
              child: Text(l.addFriendButton),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    String message;
    switch (result) {
      case AddFriendResult.added:
        message = l.friendAdded;
        break;
      case AddFriendResult.already:
        message = l.friendAlready;
        break;
      case AddFriendResult.notFound:
        message = l.friendNotFound;
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void openChat(BuildContext context, String friendId) {
    final String threadId = ensureThread(friendId);
    context.go('/home/chat/room/$threadId');
  }

  Future<void> _loadNotificationPreferences() async {
    for (final String key in _notificationOptions.keys.toList()) {
      final bool? saved = await _preferences.readBool('notify_$key');
      if (saved != null) {
        _notificationOptions[key] = saved;
      }
    }
  }
}
