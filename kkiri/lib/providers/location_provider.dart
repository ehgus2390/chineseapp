import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  final geo = GeoFlutterFirePlus.instance;
  final db = FirebaseFirestore.instance;

  Position? position;
  String? errorMessage;
  bool isUpdating = false;
  StreamSubscription<Position>? _positionSub;

  Future<bool> _ensureServiceAndPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      errorMessage = '위치 서비스가 비활성화되어 있습니다.';
      notifyListeners();
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      errorMessage = '위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.';
      notifyListeners();
      return false;
    }
    errorMessage = null;
    return true;
  }

  Future<void> _saveToFirestore(String uid, Position pos) async {
    final geoPoint = geo.point(latitude: pos.latitude, longitude: pos.longitude);

    await db.collection('users').doc(uid).set({
      'position': geoPoint.data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> startAutoUpdate(String uid) async {
    if (!await _ensureServiceAndPermission()) return;

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
          distanceFilter: 30,
        ),
      ).listen((pos) async {
        position = pos;
        await _saveToFirestore(uid, pos);
        notifyListeners();
      });
    } catch (e) {
      errorMessage = '현재 위치를 가져오지 못했습니다.';
      notifyListeners();
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> stopAutoUpdate() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> nearbyUsersStream(
      String uid, double radiusKm) {
    return db.collection('users').doc(uid).snapshots().asyncExpand((snap) {
      final data = snap.data();
      if (data == null) return Stream.empty();

      final posData = data['position'];
      if (posData is! Map<String, dynamic> ||
          posData['geopoint'] is! GeoPoint) {
        return Stream.empty();
      }

      final gp = posData['geopoint'] as GeoPoint;
      final center = geo.point(latitude: gp.latitude, longitude: gp.longitude);

      final col = db.collection('users');
      return geo
          .collection(collectionRef: col)
          .within(center: center, radiusInKm: radiusKm, field: 'position');
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
