import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import 'user_profile_popup.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> with SingleTickerProviderStateMixin {
  final geo = GeoFlutterFirePlus();
  GoogleMapController? _mapController;
  double _radiusKm = 5;
  final Map<MarkerId, Marker> _markers = {};
  StreamSubscription<List<DocumentSnapshot<Map<String, dynamic>>>>? _nearbySub;

  // 🔵 내 위치 펄스 애니메이션
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )
    ..repeat(reverse: true);
  late final Animation<double> _pulse = Tween<double>(begin: 120, end: 300)
      .animate(_pulseCtrl);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final loc = context.read<LocationProvider>();
      final uid = auth.currentUser?.uid;
      if (uid == null) {
        return;
      }
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
    final loc = context.read<LocationProvider>();
    if (loc.position == null) return;

    final center = GeoFirePoint(
        GeoPoint(loc.position!.latitude, loc.position!.longitude));
    final col = FirebaseFirestore.instance.collection('users');

    _nearbySub = geo
        .collection(collectionRef: col)
        .within(center: center, radiusInKm: _radiusKm, field: 'position')
        .listen((docs) => _buildMarkers(docs));
  }

  /// 🔹 썸네일 원형 이미지 생성 (NetworkImage → BitmapDescriptor)
  Future<BitmapDescriptor> _createProfileMarker(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final bytes = response.bodyBytes;

      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 120);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final paint = Paint()
        ..isAntiAlias = true;

      final radius = 60.0;
      final center = Offset(radius, radius);

      // 원형 마스크
      canvas.drawCircle(center, radius, paint);
      paint.blendMode = BlendMode.srcIn;

      // 원형 마스크 적용하여 이미지 그리기
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromCircle(center: center, radius: radius),
        paint,
      );

      final img = await pictureRecorder
          .endRecording()
          .toImage(radius.toInt() * 2, radius.toInt() * 2);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      return BitmapDescriptor.fromBytes(Uint8List.view(data!.buffer));
    } catch (_) {
      return BitmapDescriptor.defaultMarker; // 실패 시 기본 마커
    }
  }

  /// 🗺️ Firestore → 마커 렌더링
  Future<void> _buildMarkers(
      List<DocumentSnapshot<Map<String, dynamic>>> docs) async {
    final auth = context.read<AuthProvider>();
    final myId = auth.currentUser?.uid;
    if (myId == null) return;
    final Map<MarkerId, Marker> m = {};

    for (final d in docs) {
      final data = d.data();
      if (data == null || data['position'] == null) continue;

      final GeoPoint p = data['position'];
      final id = MarkerId(d.id);

      // 프로필 이미지 마커 적용
      BitmapDescriptor icon;
      if (data['photoUrl'] != null &&
          data['photoUrl'].toString().startsWith('http')) {
        icon = await _createProfileMarker(data['photoUrl']);
      } else {
        icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      }

      m[id] = Marker(
        markerId: id,
        position: LatLng(p.latitude, p.longitude),
        icon: icon,
        infoWindow: InfoWindow(
          title: data['displayName'] ?? 'User',
          snippet: '@${data['searchId'] ?? ''}',
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (_) =>
                  UserProfilePopup(
                    uid: d.id,
                    displayName: data['displayName'],
                    photoUrl: data['photoUrl'],
                  ),
            );
          },
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers
          ..clear()
          ..addAll(m);
      });
    }
  }

  /// 🔵 내 위치 펄스 애니메이션 (내 주변 강조)
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
                  onPressed: () =>
                      _mapController?.animateCamera(
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

  static GeoFlutterFirePlus() {}
}

// class UserProfilePopup {

// }
