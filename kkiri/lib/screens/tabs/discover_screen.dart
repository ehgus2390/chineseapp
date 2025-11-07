import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/match_provider.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final PageController _pageController = PageController();
  double _radiusKm = 10;
  int _currentIndex = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final loc = context.read<LocationProvider>();
      final uid = auth.currentUser?.uid;
      if (uid != null) {
        await loc.startAutoUpdate(uid);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handlePass(UserModel user) async {
    final auth = context.read<AuthProvider>();
    final matchProv = context.read<MatchProvider>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    await matchProv.passUser(myUid: uid, otherUid: user.uid);
  }

  Future<void> _handleLike(UserModel user) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final auth = context.read<AuthProvider>();
    final chatProv = context.read<ChatProvider>();
    final matchProv = context.read<MatchProvider>();
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final isMatch = await matchProv.sendLike(myUid: uid, otherUid: user.uid);
      if (isMatch) {
        await chatProv.createOrGetChatId(uid, user.uid);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('새로운 매칭! ${user.displayName ?? '상대방'}와 연결되었습니다.')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.displayName ?? '상대방'}에게 호감을 보냈어요.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _goToNext(int total) {
    if (!_pageController.hasClients) return;
    final nextIndex = min(_currentIndex + 1, max(total - 1, 0));
    if (nextIndex != _currentIndex) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  double? _distanceKm(Position? myPos, GeoPoint? other) {
    if (myPos == null || other == null) return null;
    final meters = Geolocator.distanceBetween(
      myPos.latitude,
      myPos.longitude,
      other.latitude,
      other.longitude,
    );
    return meters / 1000;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loc = context.watch<LocationProvider>();
    final matchProv = context.watch<MatchProvider>();

    final uid = auth.currentUser?.uid;
    if (uid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('새 인연 찾기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: '근처 사람 지도 보기',
            onPressed: () => context.go('/home/map'),
          ),
        ],
      ),
      body: loc.position == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (loc.errorMessage == null)
                      const CircularProgressIndicator()
                    else ...[
                      const Icon(Icons.location_off, size: 64, color: Colors.pinkAccent),
                      const SizedBox(height: 16),
                      Text(
                        loc.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                    if (loc.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ElevatedButton.icon(
                          onPressed: () => loc.updateMyLocation(uid),
                          icon: const Icon(Icons.refresh),
                          label: const Text('다시 시도'),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: matchProv.userStream(uid),
              builder: (context, meSnapshot) {
                if (!meSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final meData = meSnapshot.data!.data() ?? <String, dynamic>{};
                final liked = Set<String>.from(meData['likesSent'] ?? []);
                final passed = Set<String>.from(meData['passes'] ?? []);
                final matches = Set<String>.from(meData['matches'] ?? []);
                final myInterests = Set<String>.from(meData['interests'] ?? []);

                return StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
                  stream: loc.nearbyUsersStream(uid, _radiusKm),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final candidates = snapshot.data!
                        .where((doc) => doc.id != uid)
                        .where((doc) => doc.data() != null)
                        .where((doc) => !liked.contains(doc.id))
                        .where((doc) => !passed.contains(doc.id))
                        .where((doc) => !matches.contains(doc.id))
                        .map((doc) => UserModel.fromFirestore(doc))
                        .toList();

                    candidates.sort((a, b) {
                      final aScore = _scoreCandidate(a, myInterests);
                      final bScore = _scoreCandidate(b, myInterests);
                      return bScore.compareTo(aScore);
                    });

                    if (candidates.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite_border, size: 64, color: Colors.pinkAccent),
                            const SizedBox(height: 16),
                            const Text(
                              '반경 내에 새로운 추천이 없어요. 반경을 넓혀보거나 잠시 후 다시 시도해보세요!',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            _radiusSlider(),
                          ],
                        ),
                      );
                    }

                    if (_currentIndex >= candidates.length) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted || !_pageController.hasClients) return;
                        final target = candidates.isEmpty ? 0 : candidates.length - 1;
                        _pageController.jumpToPage(target);
                        setState(() => _currentIndex = target);
                      });
                    }

                    return Column(
                      children: [
                        const SizedBox(height: 12),
                        _radiusSlider(),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: candidates.length,
                            onPageChanged: (index) => setState(() => _currentIndex = index),
                            itemBuilder: (context, index) {
                              final user = candidates[index];
                              final distanceKm = _distanceKm(loc.position, user.position);
                              return _UserCard(
                                user: user,
                                distanceKm: distanceKm,
                                onPass: () async {
                                  await _handlePass(user);
                                  _goToNext(candidates.length);
                                },
                                onLike: () async {
                                  await _handleLike(user);
                                  _goToNext(candidates.length);
                                },
                                isProcessing: _isProcessing,
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _radiusSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Icon(Icons.radar, color: Colors.pinkAccent),
          Expanded(
            child: Slider(
              value: _radiusKm,
              min: 1,
              max: 30,
              divisions: 29,
              label: '${_radiusKm.toStringAsFixed(0)}km',
              onChanged: (value) => setState(() => _radiusKm = value),
            ),
          ),
        ],
      ),
    );
  }

  int _scoreCandidate(UserModel user, Set<String> myInterests) {
    final other = user.interests ?? <String>[];
    if (other.isEmpty || myInterests.isEmpty) {
      return 0;
    }
    return myInterests.intersection(other.toSet()).length;
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onPass,
    required this.onLike,
    required this.isProcessing,
    this.distanceKm,
  });

  final UserModel user;
  final Future<void> Function() onPass;
  final Future<void> Function() onLike;
  final bool isProcessing;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                    Ink.image(
                      image: NetworkImage(user.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: Colors.pink.shade50,
                      child: const Icon(Icons.person, size: 120, color: Colors.pinkAccent),
                    ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _CardInfo(user: user, distanceKm: distanceKm),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: isProcessing ? null : onPass,
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    label: const Text('패스'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: isProcessing ? null : onLike,
                    icon: const Icon(Icons.favorite, color: Colors.white),
                    label: const Text('좋아요'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  const _CardInfo({required this.user, this.distanceKm});

  final UserModel user;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final chips = (user.interests ?? <String>[])
        .map((interest) => Chip(
              label: Text(interest),
              backgroundColor: Colors.white.withOpacity(0.85),
              side: BorderSide.none,
            ))
        .toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _titleText(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                user.bio!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: -4,
                children: chips,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _titleText() {
    final agePart = user.age != null ? ' · ${user.age}세' : '';
    final distancePart = distanceKm != null ? ' · ${distanceKm!.toStringAsFixed(1)}km' : '';
    return '${user.displayName ?? '미등록 사용자'}$agePart$distancePart';
  }
}
