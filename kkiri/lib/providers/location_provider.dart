import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationProvider extends ChangeNotifier {
  Position? _position;
  Position? get position => _position;

  StreamSubscription<Position>? _sub;
  DateTime _lastUpload = DateTime.fromMillisecondsSinceEpoch(0);

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  Future<void> startAutoUpdate(String uid) async {
    final ok = await _ensurePermission();
    if (!ok) return;

    // 현재 위치 1회 업데이트
    _position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    await _upload(uid);
    notifyListeners();

    // 스트림 구독(배터리 고려: accuracy balanced, interval ~10초)
    _sub?.cancel();
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15, // 15m 이동 시 이벤트
      ),
    ).listen((pos) async {
      _position = pos;
      // 10초 쓰로틀
      if (DateTime.now().difference(_lastUpload).inSeconds >= 10) {
        await _upload(uid);
      }
      notifyListeners();
    });
  }

  Future<void> _upload(String uid) async {
    if (_position == null) return;
    _lastUpload = DateTime.now();
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'position': GeoPoint(_position!.latitude, _position!.longitude),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
