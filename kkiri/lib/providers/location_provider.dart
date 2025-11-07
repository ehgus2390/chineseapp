import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  final GeoFlutterFirePlus geo = GeoFlutterFirePlus.instance;
  final db = FirebaseFirestore.instance;

  Position? position;
  StreamSubscription<Position>? _positionSub;

  Future<bool> _ensureServiceAndPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return false;
    }
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

    final current = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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
      notifyListeners();
      await _saveToFirestore(uid, pos);
    });
  }

  Future<void> stopAutoUpdate() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }

  Future<void> updateMyLocation(String uid) async {
    if (!await _ensureServiceAndPermission()) {
      return;
    }
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    position = pos;
    await _saveToFirestore(uid, pos);
    notifyListeners();
  }

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> nearbyUsersStream(String uid, double radiusKm) {
    return db.collection('users').doc(uid).snapshots().asyncExpand((snap) {
      final data = snap.data();
      // Add robust check for position data to handle inconsistent data formats
      if (data == null) {
        return Stream.empty();
      }
      
      final positionData = data['position'];
      if (positionData is! Map<String, dynamic> || positionData['geopoint'] is! GeoPoint) {
        // If data is not in the expected format, return an empty stream to avoid crashes.
        return Stream.empty();
      }

      final point = positionData['geopoint'] as GeoPoint;
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
