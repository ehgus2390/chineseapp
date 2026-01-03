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
              child: profile.avatarUrl.isEmpty
                  ? Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.person, size: 64),
                    )
                  : Image.network(profile.avatarUrl, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 92,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'ONLINE',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                    const SizedBox(height: 8),
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
