import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MatchProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream of the signed in user's document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  /// Stream of full match profiles for the current user.
  Stream<List<Map<String, dynamic>>> matchesStream(String uid) {
    final userRef = _db.collection('users').doc(uid);
    return userRef.snapshots().asyncMap((snapshot) async {
      final matchIds = List<String>.from(snapshot.data()?['matches'] ?? []);
      if (matchIds.isEmpty) {
        return <Map<String, dynamic>>[];
      }

      final chunks = <List<String>>[];
      for (var i = 0; i < matchIds.length; i += 10) {
        chunks.add(matchIds.sublist(i, matchIds.length < i + 10 ? matchIds.length : i + 10));
      }

      final results = <Map<String, dynamic>>[];
      for (final chunk in chunks) {
        final query = await _db.collection('users').where(FieldPath.documentId, whereIn: chunk).get();
        for (final doc in query.docs) {
          results.add({'uid': doc.id, ...doc.data()});
        }
      }

      results.sort((a, b) {
        final nameA = (a['displayName'] as String? ?? '').toLowerCase();
        final nameB = (b['displayName'] as String? ?? '').toLowerCase();
        return nameA.compareTo(nameB);
      });

      return results;
    });
  }

  /// Records a like for [otherUid]. Returns `true` when it's a mutual match.
  Future<bool> sendLike({required String myUid, required String otherUid}) async {
    if (myUid == otherUid) return false;
    final myRef = _db.collection('users').doc(myUid);
    final otherRef = _db.collection('users').doc(otherUid);

    return _db.runTransaction((transaction) async {
      final mySnap = await transaction.get(myRef);
      final otherSnap = await transaction.get(otherRef);
      if (!otherSnap.exists) {
        return false;
      }

      final myData = mySnap.data() ?? <String, dynamic>{};
      final otherData = otherSnap.data() ?? <String, dynamic>{};
      final currentMatches = List<String>.from(myData['matches'] ?? []);
      if (currentMatches.contains(otherUid)) {
        return true;
      }

      transaction.set(myRef, {
        'likesSent': FieldValue.arrayUnion([otherUid]),
      }, SetOptions(merge: true));

      transaction.set(otherRef, {
        'likesReceived': FieldValue.arrayUnion([myUid]),
      }, SetOptions(merge: true));

      final otherLikes = List<String>.from(otherData['likesSent'] ?? []);
      final isMatch = otherLikes.contains(myUid);

      if (isMatch) {
        transaction.set(myRef, {
          'matches': FieldValue.arrayUnion([otherUid]),
        }, SetOptions(merge: true));
        transaction.set(otherRef, {
          'matches': FieldValue.arrayUnion([myUid]),
        }, SetOptions(merge: true));
      }

      return isMatch;
    });
  }

  Future<void> passUser({required String myUid, required String otherUid}) async {
    if (myUid == otherUid) return;
    await _db.collection('users').doc(myUid).set({
      'passes': FieldValue.arrayUnion([otherUid]),
    }, SetOptions(merge: true));
  }
}