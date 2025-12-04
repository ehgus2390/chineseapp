import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  final GeoFlutterFirePlus geo = GeoFlutterFirePlus.instance;
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
    if (!await _ensureServiceAndPermission()) {
      return;
    }

    try {
      isUpdating = true;
      notifyListeners();
      final current = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      position = current;
      await _saveToFirestore(uid, current);
      errorMessage = null;
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
      }, onError: (Object e) {
        errorMessage = '위치 업데이트 중 오류가 발생했습니다.';
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

  Future<void> updateMyLocation(String uid) async {
    if (!await _ensureServiceAndPermission()) {
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      position = pos;
      await _saveToFirestore(uid, pos);
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = '위치를 갱신하지 못했습니다.';
      notifyListeners();
    }
  }

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> nearbyUsersStream(String uid, double radiusKm) {
    return db.collection('users').doc(uid).snapshots().asyncExpand((snap) {
      final data = snap.data();
      GeoPoint? point;

      // Prefer the saved Firestore position when it exists and is well-formed.
      final positionData = data?['position'];
      if (positionData is Map<String, dynamic> && positionData['geopoint'] is GeoPoint) {
        point = positionData['geopoint'] as GeoPoint;
      }

      // Fall back to the latest in-memory position to avoid empty results for new users
      // whose Firestore profile hasn't been updated yet.
      if (point == null && position != null) {
        point = GeoPoint(position!.latitude, position!.longitude);
      }

      if (point == null) {
        return Stream.value(<DocumentSnapshot<Map<String, dynamic>>>[]);
      }

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
