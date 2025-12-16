import 'package:cloud_firestore/cloud_firestore.dart';

Future<Set<String>> getBlockedUids(String myUid) async {
  final snap = await FirebaseFirestore.instance
      .collection('users')
      .doc(myUid)
      .collection('blocked')
      .get();

  return snap.docs.map((d) => d.id).toSet();
}
