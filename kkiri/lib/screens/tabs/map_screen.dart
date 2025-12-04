import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
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
      await context.read<LocationProvider>().updateMyLocation(auth.currentUser!.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locProv = context.watch<LocationProvider>();
    final chatProv = context.read<ChatProvider>();
    final uid = auth.currentUser!.uid;

    return StreamBuilder<List<DocumentSnapshot>>(
      stream: locProv.nearbyUsersStream(uid, radiusKm),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final users = snap.data!;
        final markers = <Marker>{};

        for (final u in users) {
          if (u.id == uid) continue;
          final data = u.data() as Map<String, dynamic>;
          final posData = data['position'] as Map<String, dynamic>?;
          final geoPoint = posData?['geopoint'];
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
                    Navigator.pushNamed(context, '/chatroom', arguments: chatId);
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
