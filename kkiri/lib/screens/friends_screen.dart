import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/profile_sheet.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final AppLocalizations l = AppLocalizations.of(context);
    final me = state.me;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l.nearbyFriends, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(me.latitude, me.longitude),
                initialZoom: 13,
                interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.kkiri.app',
                ),
                CircleLayer(circles: [
                  CircleMarker(
                    point: LatLng(me.latitude, me.longitude),
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    borderStrokeWidth: 2,
                    borderColor: Theme.of(context).colorScheme.primary,
                    radius: state.nearbyRadiusKm * 1000,
                  )
                ]),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(me.latitude, me.longitude),
                      width: 50,
                      height: 50,
                      child: const _MarkerAvatar(isMe: true),
                    ),
                    ...state.nearbyProfiles.map((profile) {
                      return Marker(
                        point: LatLng(profile.latitude, profile.longitude),
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () => showProfileSheet(
                            context,
                            profile,
                            onChat: () {
                              Navigator.of(context).pop();
                              state.openChat(context, profile.id);
                            },
                          ),
                          child: _MarkerAvatar(avatarUrl: profile.avatarUrl),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l.radiusLabel(state.nearbyRadiusKm.toStringAsFixed(1)),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text(l.myFriends, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text('${state.friends.length}', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        if (state.friends.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                l.emptyFriends,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...state.friends.map((profile) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(profile.avatarUrl)),
                title: Text(profile.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${profile.statusMessage}\n${state.formatDistance(profile)}'),
                isThreeLine: true,
                trailing: FilledButton.tonal(
                  onPressed: () => state.openChat(context, profile.id),
                  child: Text(l.startChat),
                ),
                onTap: () => showProfileSheet(
                  context,
                  profile,
                  onChat: () {
                    Navigator.of(context).pop();
                    state.openChat(context, profile.id);
                  },
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _MarkerAvatar extends StatelessWidget {
  const _MarkerAvatar({this.avatarUrl, this.isMe = false});

  final String? avatarUrl;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    if (isMe) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const Icon(Icons.person, color: Colors.white),
      );
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
          ),
        ],
      ),
      child: CircleAvatar(backgroundImage: NetworkImage(avatarUrl!)),
    );
  }
}
