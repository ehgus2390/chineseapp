// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
//
// class FriendsProvider extends ChangeNotifier {
//   final _db = FirebaseFirestore.instance;
//
//   Future<Map<String, dynamic>?> findUserBySearchId(String searchId) async {
//     final q = await _db.collection('users').where('searchId', isEqualTo: searchId).limit(1).get();
//     if (q.docs.isEmpty) return null;
//     final d = q.docs.first.data();
//     return {'uid': q.docs.first.id, ...d};
//   }
//
//   Future<void> addFriendBoth(String myUid, String otherUid) async {
//     final myRef = _db.collection('users').doc(myUid);
//     final otherRef = _db.collection('users').doc(otherUid);
//     await _db.runTransaction((tx) async {
//       tx.update(myRef, {'friends': FieldValue.arrayUnion([otherUid])});
//       tx.update(otherRef, {'friends': FieldValue.arrayUnion([myUid])});
//     });
//     notifyListeners();
//   }
//
//   Stream<List<Map<String, dynamic>>> myFriendsStream(String myUid) {
//     final userRef = _db.collection('users').doc(myUid);
//     return userRef.snapshots().asyncMap((snap) async {
//       final friends = List<String>.from(snap.data()?['friends'] ?? []);
//       if (friends.isEmpty) return [];
//       final chunks = <List<String>>[];
//       // Firestore in query 10개 제한을 고려한 chunk
//       for (var i = 0; i < friends.length; i += 10) {
//         chunks.add(friends.sublist(i, i + 10 > friends.length ? friends.length : i + 10));
//       }
//       final results = <Map<String, dynamic>>[];
//       for (final chunk in chunks) {
//         final qs = await _db.collection('users').where(FieldPath.documentId, whereIn: chunk).get();
//         for (final d in qs.docs) {
//           results.add({'uid': d.id, ...d.data()});
//         }
//       }
//       return results;
//     });
//   }
// }
