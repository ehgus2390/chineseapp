import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/interest_options.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
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
  double _radiusKm = 5;
  int _currentIndex = 0;
  bool _isProcessing = false;
  final Set<String> _selectedFilters = {};

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
    final l10n = context.l10n;
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
          SnackBar(content: Text(l10n.newMatchSnack)),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.likeSentSnack)));
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
    final l10n = context.l10n;

    final uid = auth.currentUser?.uid;
    if (uid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.discoverTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: l10n.openMap,
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
                        loc.errorMessage ?? l10n.pleaseShareLocation,
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
                          label: Text(l10n.retry),
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
                    var candidates = snapshot.data!
                        .where((doc) => doc.id != uid)
                        .where((doc) => doc.data() != null)
                        .where((doc) => !liked.contains(doc.id))
                        .where((doc) => !passed.contains(doc.id))
                        .where((doc) => !matches.contains(doc.id))
                        .map((doc) => UserModel.fromFirestore(doc))
                        .toList();

                    if (_selectedFilters.isNotEmpty) {
                      candidates = candidates
                          .where((user) =>
                              user.interests?.any((interest) => _selectedFilters.contains(interest)) ?? false)
                          .toList();
                    }

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
                            Text(
                              l10n.noCandidates,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            _radiusSlider(l10n),
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
                        _radiusSlider(l10n),
                        _interestFilterChips(l10n),
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
                                l10n: l10n,
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

  Widget _radiusSlider(AppLocalizations l10n) {
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
              label: l10n.radiusDisplay(_radiusKm),
              onChanged: (value) => setState(() => _radiusKm = value),
            ),
          ),
          Text(l10n.radiusLabel),
        ],
      ),
    );
  }

  Widget _interestFilterChips(AppLocalizations l10n) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.interestFilterLabel, style: Theme.of(context).textTheme.bodySmall),
                Text(l10n.recDistanceTag, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          ...kInterestOptions.map((option) {
            final selected = _selectedFilters.contains(option.id);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(l10n.interestLabelText(option.id)),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedFilters.add(option.id);
                    } else {
                      _selectedFilters.remove(option.id);
                    }
                  });
                },
              ),
            );
          }),
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
    required this.l10n,
    this.distanceKm,
  });

  final UserModel user;
  final Future<void> Function() onPass;
  final Future<void> Function() onLike;
  final bool isProcessing;
  final double? distanceKm;
  final AppLocalizations l10n;

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
                    child: _CardInfo(user: user, distanceKm: distanceKm, l10n: l10n),
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
                    label: Text(l10n.passButton),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: isProcessing ? null : onLike,
                    icon: const Icon(Icons.favorite, color: Colors.white),
                    label: Text(l10n.likeButton),
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
  const _CardInfo({required this.user, this.distanceKm, required this.l10n});

  final UserModel user;
  final double? distanceKm;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final chips = (user.interests ?? <String>[])
        .map((interest) => Chip(
              label: Text(
                kInterestOptionIds.contains(interest)
                    ? l10n.interestLabelText(interest)
                    : interest,
              ),
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
    return '${user.displayName ?? l10n.profileTitle}$agePart$distancePart';
  }
}
