import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/matching_rules.dart';

class LocationProvider extends ChangeNotifier {
  final FirebaseFirestore db = FirebaseFirestore.instance;

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

    errorMessage = null;
    return true;
  }

  // ───────────────────────── Firestore 저장 ─────────────────────────
  Future<void> _saveToFirestore(String uid, Position pos) async {
    final geoPoint = GeoFirePoint(GeoPoint(pos.latitude, pos.longitude));

    await db.collection("users").doc(uid).set({
      "position": geoPoint.data, // {"geopoint":, "geohash":}
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ───────────────────────── 자동 업데이트 ─────────────────────────
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
      errorMessage = "위치 갱신 실패";
      notifyListeners();
    }
  }

  // ───────────────────────── 주변 사용자 스트림 ─────────────────────────
  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> nearbyUsersStream(
      String uid,
      double radiusKm,
      ) {
    final usersRef = db.collection("users");

    return usersRef.doc(uid).snapshots().asyncExpand((snap) {

      final myData = snap.data();
      if (myData == null) return Stream.value([]);

      final myGender = myData['gender'] as String?;
      final myCountry = myData['country'] as String?;
      if (myGender == null || myCountry == null) return Stream.value([]);

      final posData = myData["position"];
      if (posData is! Map<String, dynamic>) return Stream.value([]);

      if (posData["geopoint"] is! GeoPoint) return Stream.value([]);

      final centerGeo = posData["geopoint"] as GeoPoint;
      final center = GeoFirePoint(centerGeo);

      final geoRef = GeoCollectionReference<Map<String, dynamic>>(usersRef);

      return geoRef.subscribeWithin(
        center: center,
        radiusInKm: radiusKm,
        field: "position",
        geopointFrom: (map) =>
        (map["position"] as Map<String, dynamic>)["geopoint"] as GeoPoint,
        strictMode: true,
      ).map((docs) => docs.where((doc) {
        if (doc.id == uid) return false;
        final data = doc.data();
        final otherGender = data?['gender'] as String?;
        final otherCountry = data?['country'] as String?;
        return isTargetMatch(myGender, myCountry, otherGender, otherCountry);
      }).toList());
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
