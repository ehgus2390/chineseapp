import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../chat/chat_room_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/user_marker_popup.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final double radiusKm = 5.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final uid = auth.currentUser?.uid;
      if (uid == null) return;
      await context.read<LocationProvider>().updateMyLocation(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locProv = context.watch<LocationProvider>();
    final chatProv = context.read<ChatProvider>();
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('로그인이 필요합니다. 다시 로그인 해주세요.'),
          ),
        ),
      );
    }

    return StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
      stream: locProv.nearbyUsersStream(uid, radiusKm),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snap.data ?? <DocumentSnapshot<Map<String, dynamic>>>[];
        if (users.isEmpty) {
          return const Center(child: Text('주변 사용자를 불러오지 못했습니다. 위치를 다시 확인해주세요.'));
        }
        final markers = <Marker>{};

        for (final u in users) {
          if (u.id == uid) continue;
          final data = u.data();
          if (data == null) continue;
          final position = data['position'];
          if (position is! Map<String, dynamic>) continue;
          final geoPoint = position['geopoint'];
          if (geoPoint is! GeoPoint) continue;
          final LatLng pos = LatLng(geoPoint.latitude, geoPoint.longitude);

          markers.add(Marker(
            markerId: MarkerId(u.id),
            position: pos,
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => UserMarkerPopup(
                  uid: u.id,
                  displayName: data['displayName'] ?? 'User',
                  photoUrl: data['photoUrl'],
                  onChatPressed: () async {
                    final chatId = await chatProv.createOrGetChatId(uid, u.id);
                    if (!mounted) return;
                    Navigator.pop(context);
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          peerId: u.id,
                          peerName: data['displayName'] ?? 'User',
                          peerPhoto: data['photoUrl'] as String?,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ));
        }

        return GoogleMap(
          myLocationEnabled: true,
          initialCameraPosition: const CameraPosition(target: LatLng(37.5665, 126.9780), zoom: 13),
          markers: markers,
        );
      },
    );
  }
}
