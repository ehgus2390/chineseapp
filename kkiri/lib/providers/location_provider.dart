import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:flutter/foundation.dart';

class LocationProvider extends ChangeNotifier {
  final geo = GeoFlutterFirePlus();
  final db = FirebaseFirestore.instance;

  Future<void> updateMyLocation(String uid) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final geoPoint = geo.point(latitude: pos.latitude, longitude: pos.longitude);
    await db.collection('users').doc(uid).update({
      'position': geoPoint.geoPoint,
      'geohash': geoPoint.hash,
    });
  }

  Stream<List<DocumentSnapshot>> nearbyUsersStream(String uid, double radiusKm) {
    return db.collection('users').doc(uid).snapshots().asyncExpand((snap) {
      final data = snap.data();
      if (data == null || data['position'] == null) return const Stream.empty();
      final center = geo.point(
        latitude: data['position'].latitude,
        longitude: data['position'].longitude,
      );
      final collectionRef = db.collection('users');
      return geo.collection(collectionRef: collectionRef)
          .within(center: center, radius: radiusKm, field: 'position');
    });
  }
}
