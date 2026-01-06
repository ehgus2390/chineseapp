import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../state/app_state.dart';
import '../l10n/app_localizations.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();
  bool _seeded = false;
  bool _updatingLocation = false;
  double _distanceKm = 30;

  @override
  void dispose() {
    latCtrl.dispose();
    lngCtrl.dispose();
    super.dispose();
  }

  void _seedFromProfile(AppState state) {
    if (_seeded) return;
    final me = state.meOrNull;
    if (me == null) return;
    _seeded = true;
    _distanceKm = me.distanceKm;
    if (me.location != null) {
      latCtrl.text = me.location!.latitude.toStringAsFixed(6);
      lngCtrl.text = me.location!.longitude.toStringAsFixed(6);
    }
  }

  Future<void> _useCurrentLocation(AppState state) async {
    final l = AppLocalizations.of(context);
    final hasService = await Geolocator.isLocationServiceEnabled();
    if (!hasService) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.locationServiceOff)));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.locationPermissionDenied)));
      return;
    }

    setState(() => _updatingLocation = true);
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    latCtrl.text = position.latitude.toStringAsFixed(6);
    lngCtrl.text = position.longitude.toStringAsFixed(6);
    await _savePreferences(state);

    if (!mounted) return;
    setState(() => _updatingLocation = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.locationUpdated)));
  }

  Future<void> _savePreferences(AppState state) async {
    GeoPoint? location;
    final double? lat = double.tryParse(latCtrl.text.trim());
    final double? lng = double.tryParse(lngCtrl.text.trim());
    if (lat != null && lng != null) {
      location = GeoPoint(lat, lng);
    }
    await state.updateMatchPreferences(
      distanceKm: _distanceKm,
      location: location,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations.of(context);
    _seedFromProfile(state);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F4),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Text(
                    l.chatTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.black),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.black),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _FilterChip(label: l.chatFilterAll, selected: true),
                  _FilterChip(label: l.chatFilterLikes, selected: false),
                  _FilterChip(label: l.chatFilterNew, selected: false),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2E6EA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.distance, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(l.distanceHint),
                  Slider(
                    min: 1,
                    max: 200,
                    value: _distanceKm.clamp(1, 200),
                    label: '${_distanceKm.toStringAsFixed(0)} km',
                    onChanged: (value) => setState(() => _distanceKm = value),
                    onChangeEnd: (_) => _savePreferences(state),
                  ),
                  const SizedBox(height: 8),
                  Text(l.location, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: latCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: l.latitude),
                          onSubmitted: (_) => _savePreferences(state),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: lngCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: l.longitude),
                          onSubmitted: (_) => _savePreferences(state),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _updatingLocation
                          ? null
                          : () => _useCurrentLocation(state),
                      child: _updatingLocation
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l.useCurrentLocation),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.matches.isEmpty
                  ? Center(
                      child: Text(
                        l.chatEmpty,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.matches.length,
                      itemBuilder: (_, i) {
                        final match = state.matches[i];
                        final partnerId = match.userIds
                            .firstWhere((id) => id != state.me.id, orElse: () => '');
                        if (partnerId.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return FutureBuilder(
                          future: state.fetchProfile(partnerId),
                          builder: (context, snapshot) {
                            final profile = snapshot.data;
                            final avatar = profile?.photoUrl ?? '';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    avatar.isEmpty ? null : NetworkImage(avatar),
                                child: avatar.isEmpty
                                    ? const Icon(Icons.person, color: Colors.black)
                                    : null,
                              ),
                              title: Text(
                                profile?.name ?? '',
                                style: const TextStyle(color: Colors.black),
                              ),
                              subtitle: Text(
                                match.lastMessage.isEmpty
                                    ? l.startChat
                                    : match.lastMessage,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              trailing: Text(
                                _formatDate(match.lastMessageAt),
                                style: const TextStyle(color: Colors.black45),
                              ),
                              onTap: () => context.go('/home/chat/room/${match.id}'),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _FilterChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.white12,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : Colors.black45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '';
  return '${date.month}/${date.day}';
}
