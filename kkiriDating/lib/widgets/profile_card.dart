import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../l10n/app_localizations.dart';

class ProfileCard extends StatelessWidget {
  final Profile profile;
  final VoidCallback onLike;
  final VoidCallback onPass;
  final double? distanceKm;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.onLike,
    required this.onPass,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final interests = profile.interests.take(3).toList();
    final String? distanceLabel = distanceKm == null
        ? null
        : '${distanceKm!.toStringAsFixed(1)}km';
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          children: [
            Positioned.fill(
              child: (profile.photoUrl == null || profile.photoUrl!.isEmpty)
                  ? Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.person, size: 64),
                    )
                  : Image.network(
                      profile.photoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const SizedBox(
                            height: 32,
                            width: 32,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.person, size: 64),
                      ),
                    ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.65),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Dot(active: true),
                  _Dot(active: false),
                  _Dot(active: false),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 92,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.country.isEmpty
                        ? '${profile.name}, ${profile.age}'
                        : '${profile.name}, ${profile.age} · ${profile.country}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.work, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          profile.occupation.isEmpty
                              ? profile.bio
                              : profile.occupation,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (distanceLabel != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          distanceLabel,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Wrap(
                    spacing: 6,
                    children: interests
                        .map((label) => Chip(
                              label: Text(label),
                              backgroundColor: Colors.white.withOpacity(0.2),
                              labelStyle:
                                  const TextStyle(color: Colors.white),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ActionButton(
                    icon: Icons.close,
                    onPressed: onPass,
                    background: Colors.white,
                    foreground: Colors.black87,
                    label: l.pass,
                  ),
                  _ActionButton(
                    icon: Icons.favorite,
                    onPressed: onLike,
                    background: const Color(0xFFE94D8A),
                    foreground: Colors.white,
                    label: l.like,
                  ),
                  _ActionButton(
                    icon: Icons.chat_bubble,
                    onPressed: () {},
                    background: Colors.white.withOpacity(0.85),
                    foreground: Colors.black87,
                    label: l.tabChat,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.black45,
                child: const Icon(Icons.more_horiz, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color background;
  final Color foreground;
  final String label;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    required this.background,
    required this.foreground,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: background,
          child: IconButton(
            icon: Icon(icon, color: foreground),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;

  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 18 : 8,
      height: 6,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white54,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
