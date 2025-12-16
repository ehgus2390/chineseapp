import 'package:cloud_firestore/cloud_firestore.dart';

class BlockService {
  final _db = FirebaseFirestore.instance;

  Stream<Set<String>> blockedUidsStream(String myUid) {
    return _db
        .collection('users')
        .doc(myUid)
        .collection('blocked')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }
}
