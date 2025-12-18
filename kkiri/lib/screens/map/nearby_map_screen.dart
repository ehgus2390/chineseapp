// lib/screens/map/nearby_map_screen.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import 'user_profile_popup.dart';

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  double _radiusKm = 5;

  final Map<MarkerId, Marker> _markers = {};
  StreamSubscription<List<DocumentSnapshot<Map<String, dynamic>>>>? _nearbySub;

  // 🔵 내 위치 펄스 애니메이션
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  late final Animation<double> _pulse =
      Tween<double>(begin: 120, end: 300).animate(_pulseCtrl);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final loc = context.read<LocationProvider>();
      final uid = auth.currentUser?.uid;
      if (uid == null) return;

      // Firestore에 내 위치 저장 + provider.position 갱신
      await loc.startAutoUpdate(uid);
      _subscribeNearby();
    });
  }

  @override
  void dispose() {
    _nearbySub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  /// 주변 사용자 구독
  void _subscribeNearby() {
    _nearbySub?.cancel();

    final auth = context.read<AuthProvider>();
    final loc = context.read<LocationProvider>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    _nearbySub = loc.nearbyUsersStream(uid, _radiusKm).listen(_buildMarkers);
  }

  /// 🔹 썸네일 원형 이미지 → 마커 아이콘으로 변환
  Future<BitmapDescriptor> _createProfileMarker(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final bytes = response.bodyBytes;

      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 120);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final paint = Paint()..isAntiAlias = true;

      const radius = 60.0;
      const center = Offset(radius, radius);

      // 원형 마스크
      canvas.drawCircle(center, radius, paint);
      paint.blendMode = BlendMode.srcIn;

      // 마스크 적용 후 이미지 그리기
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        Rect.fromCircle(center: center, radius: radius),
        paint,
      );

      final img = await pictureRecorder
          .endRecording()
          .toImage((radius * 2).toInt(), (radius * 2).toInt());
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      return BitmapDescriptor.fromBytes(Uint8List.view(data!.buffer));
    } catch (_) {
      return BitmapDescriptor.defaultMarker; // 실패 시 기본 마커
    }
  }

  /// 🗺 Firestore → 마커로 렌더링
  Future<void> _buildMarkers(
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final auth = context.read<AuthProvider>();
    final myId = auth.currentUser?.uid;
    if (myId == null) return;

    final Map<MarkerId, Marker> m = {};

    // 내 관심사
    final myDoc =
        await FirebaseFirestore.instance.collection('users').doc(myId).get();
    final myData = myDoc.data();
    if (myData == null) return;
    final myInterests = Set<String>.from(myData['interests'] ?? []);

    for (final d in docs) {
      final data = d.data();
      if (data == null) continue;
      final posData = data['position'];
      if (posData is! Map<String, dynamic>) continue;
      final gp = posData['geopoint'];
      if (gp is! GeoPoint) continue;

      final markerId = MarkerId(d.id);

      final userInterests = Set<String>.from(data['interests'] ?? []);
      final hasCommonInterests =
          myInterests.intersection(userInterests).isNotEmpty;

      BitmapDescriptor icon;
      if (hasCommonInterests) {
        icon =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      } else if (data['photoUrl'] != null &&
          data['photoUrl'].toString().startsWith('http')) {
        icon = await _createProfileMarker(data['photoUrl'] as String);
      } else {
        icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      }

      m[markerId] = Marker(
        markerId: markerId,
        position: LatLng(gp.latitude, gp.longitude),
        icon: icon,
        infoWindow: InfoWindow(
          title: data['displayName'] ?? 'User',
          snippet: '@${data['searchId'] ?? ''}',
        ),
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
      );
    }

    if (!mounted) return;
    setState(() {
      _markers
        ..clear()
        ..addAll(m);
    });
  }

  /// 🔵 내 위치 펄스 서클
  Set<Circle> _buildPulseCircle() {
    final loc = context.read<LocationProvider>();
    if (loc.position == null) return {};
    final myCenter = LatLng(loc.position!.latitude, loc.position!.longitude);
    final radiusMeters = _pulse.value;

    return {
      Circle(
        circleId: const CircleId('pulse'),
        center: myCenter,
        radius: radiusMeters,
        fillColor: Colors.blue.withOpacity(0.15),
        strokeColor: Colors.blue.withOpacity(0.4),
        strokeWidth: 2,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationProvider>();

    if (loc.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('주변 사용자')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '위치 공유를 허용하면 추천 친구를 지도에서 볼 수 있습니다.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => GoRouter.of(context).go('/home/settings'),
                  icon: const Icon(Icons.settings),
                  label: const Text('설정으로 이동'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (loc.position == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final myPos = LatLng(loc.position!.latitude, loc.position!.longitude);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        return Scaffold(
          appBar: AppBar(title: const Text('주변 사용자')),
          body: GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(target: myPos, zoom: 14),
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
                    onChangeEnd: (_) => _subscribeNearby(),
                  ),
                ),
                IconButton(
                  tooltip: '내 위치로 이동',
                  icon: const Icon(Icons.my_location),
                  onPressed: () => _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(myPos, 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
