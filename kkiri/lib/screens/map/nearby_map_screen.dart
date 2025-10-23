import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import 'user_profile_popup.dart';

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> with SingleTickerProviderStateMixin {
  final geo = GeoFlutterFire();
  GoogleMapController? _mapController;
  double _radiusKm = 5;
  final Map<MarkerId, Marker> _markers = {};
  final Map<CircleId, Circle> _circles = {};

  StreamSubscription<List<DocumentSnapshot>>? _nearbySub;

  // 펄스 애니메이션 (내 위치 강조)
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);
  late final Animation<double> _pulse = Tween<double>(begin: 120, end: 300).animate(_pulseCtrl); // 미터

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final loc = context.read<LocationProvider>();
      await loc.startAutoUpdate(auth.currentUser!.uid);
      _subscribeNearby();
    });
  }

  @override
  void dispose() {
    _nearbySub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _subscribeNearby() {
    _nearbySub?.cancel();
    final loc = context.read<LocationProvider>();
    if (loc.position == null) return;

    final center = geo.point(latitude: loc.position!.latitude, longitude: loc.position!.longitude);
    final col = FirebaseFirestore.instance.collection('users');

    _nearbySub = geo.collection(collectionRef: col)
        .within(center: center, radius: _radiusKm, field: 'position')
        .listen((docs) => _buildMarkers(docs));
  }

  void _buildMarkers(List<DocumentSnapshot> docs) {
    final auth = context.read<AuthProvider>();
    final me = auth.currentUser!.uid;
    final Map<MarkerId, Marker> m = {};

    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      if (data['position'] == null) continue;
      final GeoPoint p = data['position'];

      final id = MarkerId(d.id);
      m[id] = Marker(
        markerId: id,
        position: LatLng(p.latitude, p.longitude),
        icon: d.id == me
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
            : BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: data['displayName'] ?? 'User',
          snippet: '@${data['searchId'] ?? ''}',
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (_) => UserProfilePopup(
                uid: d.id,
                displayName: data['displayName'],
                photoUrl: data['photoUrl'],
              ),
            );
          },
        ),
      );
    }

    setState(() => _markers
      ..clear()
      ..addAll(m));
  }

  Set<Circle> _buildPulseCircle() {
    final loc = context.read<LocationProvider>();
    if (loc.position == null) return {};
    final myCenter = LatLng(loc.position!.latitude, loc.position!.longitude);

    // 펄스 반경은 애니메이션 값(미터)로 표현
    final currentMeters = _pulse.value;
    final c = Circle(
      circleId: const CircleId('pulse'),
      center: myCenter,
      radius: currentMeters,
      fillColor: Colors.blue.withOpacity(0.12),
      strokeColor: Colors.blue.withOpacity(0.30),
      strokeWidth: 1,
    );
    return {c};
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationProvider>();
    if (loc.position == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final myLatLng = LatLng(loc.position!.latitude, loc.position!.longitude);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        return Scaffold(
          appBar: AppBar(title: const Text('주변 사용자')),
          body: GoogleMap(
            onMapCreated: (c) => _mapController = c,
            initialCameraPosition: CameraPosition(target: myLatLng, zoom: 14),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers.values.toSet(),
            circles: _buildPulseCircle(),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text('반경'),
                Expanded(
                  child: Slider(
                    value: _radiusKm,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: '${_radiusKm.toInt()} km',
                    onChanged: (v) => setState(() => _radiusKm = v),
                    onChangeEnd: (_) => _subscribeNearby(), // 반경 바뀌면 재구독
                  ),
                ),
                IconButton(
                  tooltip: '내 위치로 이동',
                  icon: const Icon(Icons.my_location),
                  onPressed: () => _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(myLatLng, 14),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
            label: const Text('확대'),
            icon: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
