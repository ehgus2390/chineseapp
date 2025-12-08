import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/matching_rules.dart';

class LocationProvider extends ChangeNotifier {
  final GeoFlutterFirePlus geo = GeoFlutterFirePlus();
  final db = FirebaseFirestore.instance;

  Position? position;
  String? errorMessage;
  bool isUpdating = false;

  StreamSubscription<Position>? _positionSub;

  // ───────────────────────── 서비스/권한 체크 ─────────────────────────
  Future<bool> _ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      errorMessage = '위치 서비스가 꺼져 있습니다.';
      notifyListeners();
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      errorMessage = '위치 권한이 필요합니다.';
      notifyListeners();
      return false;
    }

    // 문제 없으면 에러 초기화
    errorMessage = null;
    return true;
  }

  // ───────────────────────── Firestore 저장 ─────────────────────────
  Future<void> _saveToFirestore(String uid, Position pos) async {
    final geoPoint = GeoFirePoint(GeoPoint(pos.latitude, pos.longitude));

    await db.collection("users").doc(uid).set(
      {
        "position": geoPoint.data, // {"geopoint":, "geohash":}
        "updatedAt": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ───────────────────────── 자동 업데이트 ─────────────────────────
  Future<void> startAutoUpdate(String uid) async {
    final settingsSnap = await db.collection('users').doc(uid).get();
    final shareLocation = settingsSnap.data()?['shareLocation'] != false;
    if (!shareLocation) {
      errorMessage = '위치 공유가 꺼져 있습니다. 설정에서 켜주세요.';
      notifyListeners();
      return;
    }

    if (!await _ensurePermission()) return;

    try {
      isUpdating = true;
      notifyListeners();

      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      position = current;
      await _saveToFirestore(uid, current);
      notifyListeners();

      // 이전 스트림 정리
      await _positionSub?.cancel();

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen((pos) async {
        position = pos;
        await _saveToFirestore(uid, pos);
        notifyListeners();
      });
    } catch (e) {
      errorMessage = "위치 업데이트 실패: $e";
      isUpdating = false;
      notifyListeners();
    }
  }

  // ───────────────────────── 수동 갱신 (updateMyLocation) ─────────────────────────
  Future<void> updateMyLocation(String uid) async {
    if (!await _ensurePermission()) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      position = pos;
      await _saveToFirestore(uid, pos);
      notifyListeners();
    } catch (e) {
      errorMessage = "위치 갱신 실패: $e";
      notifyListeners();
    }
  }

  Future<void> stopAutoUpdate() async {
    await _positionSub?.cancel();
    _positionSub = null;
    isUpdating = false;
    notifyListeners();
  }

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> nearbyUsersStream(String uid, double radiusKm) {
    return db.collection('users').doc(uid).snapshots().asyncExpand((snap) {
      final data = snap.data();
      if (data == null || data['position'] == null) {
        return Stream<List<DocumentSnapshot<Map<String, dynamic>>>>.empty();
      }
      final point = data['position'] as GeoPoint;
      final center = geo.point(latitude: point.latitude, longitude: point.longitude);
      final collectionRef = db.collection('users');
      return geo
          .collection(collectionRef: collectionRef)
          .within(center: center, radiusInKm: radiusKm, field: 'position');
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
