import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  final db = FirebaseFirestore.instance;

  Position? position;
  String? errorMessage;
  bool isUpdating = false;

  StreamSubscription<Position>? _positionSub;

  // ───────────────────────── 권한 체크 ─────────────────────────
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

    errorMessage = null;
    return true;
  }

  // ───────────────────────── 위치 저장 ─────────────────────────
  Future<void> _saveToFirestore(String uid, Position pos) async {
    await db.collection("users").doc(uid).set(
      {
        "position": GeoPoint(pos.latitude, pos.longitude),
        "updatedAt": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }


  // ───────────────────────── 자동 위치 업데이트 ─────────────────────────
  Future<void> startAutoUpdate(String uid) async {
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

  // ───────────────────────── 수동 위치 갱신 ─────────────────────────
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
    isUpdating = false;
    notifyListeners();
  }

  // ───────────────────────── 근처 사용자 쿼리 ─────────────────────────
  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> nearbyUsersStream(
      String uid,
      double radiusKm,
      ) {
    // final usersRef = db.collection('users');
    //
    // return usersRef.doc(uid).snapshots().asyncExpand((snap) {
    //   final data = snap.data();
    //   if (data == null || data['position'] == null) {
    //     return Stream<List<DocumentSnapshot<Map<String, dynamic>>>>.value([]);
    //   }
    //
    //   final positionData = data['position'];
    //   final centerGeoPoint = positionData['geopoint'] as GeoPoint;
    //
    //   final center = GeoFirePoint(centerGeoPoint);
    //
    //   final geoRef = GeoCollectionReference<Map<String, dynamic>>(usersRef);
    //
    //   return geoRef.subscribeWithin(
    //     center: center,
    //     radiusInKm: radiusKm,
    //     field: "position",
    //     geopointFrom: (map) =>
    //     (map['position'] as Map<String, dynamic>)['geopoint'] as GeoPoint,
    //     strictMode: true,
    //   );
    // });
    return const Stream.empty();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
