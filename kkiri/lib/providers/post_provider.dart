import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PostProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> postsStream() {
    return _db.collection('posts').orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> popularPostsStream({int minLikes = 10}) {
    return _db.collection('posts')
        .where('likesCount', isGreaterThanOrEqualTo: minLikes)
        .orderBy('likesCount', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<String> addPost(String uid, String text, {String? imageUrl}) async {
    final ref = await _db.collection('posts').add({
      'authorId': uid,
      'text': text,
      'imageUrl': imageUrl,
      'likesCount': 0,
      'commentsCount': 0,
      'isPopular': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> toggleLike(String postId, String uid) async {
    final likeRef = _db.collection('posts').doc(postId).collection('likes').doc(uid);
    final postRef = _db.collection('posts').doc(postId);
    await _db.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      final postSnap = await tx.get(postRef);
      int likes = (postSnap.data()?['likesCount'] ?? 0) as int;
      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.update(postRef, {'likesCount': likes - 1});
      } else {
        tx.set(likeRef, {'liked': true});
        tx.update(postRef, {'likesCount': likes + 1});
      }
    });
  }

  Future<void> addComment(String postId, String authorId, String text) async {
    await _db.collection('posts').doc(postId).collection('comments').add({
      'authorId': authorId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream(String postId) {
    return _db.collection('posts').doc(postId).collection('comments')
        .orderBy('createdAt', descending: false).snapshots();
  }
}
