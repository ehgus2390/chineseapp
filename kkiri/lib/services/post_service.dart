// lib/services/post_service.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class PostService {
  PostService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _postsCollection =>
      _firestore.collection('posts');

  Stream<QuerySnapshot<Map<String, dynamic>>> listenPosts() {
    return _postsCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenPopularPosts() {
    return _postsCollection
        .orderBy('likesCount', descending: true)
        .limit(10)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenComments(String postId) {
    return _postsCollection
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> createPost(String uid, String content) async {
    await _postsCollection.add({
      'authorId': uid,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
    });
  }

  Future<void> addComment(String postId, String uid, String text) async {
    final commentsRef = _postsCollection.doc(postId).collection('comments');
    await commentsRef.add({
      'authorId': uid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleLike(String postId, String uid) async {
    final postRef = _postsCollection.doc(postId);
    final likeRef = postRef.collection('likes').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);
      if (!postSnapshot.exists) {
        throw StateError('Post no longer exists');
      }

      final likeSnapshot = await transaction.get(likeRef);
      final currentLikes = (postSnapshot.data()?['likesCount'] as int?) ?? 0;

      if (likeSnapshot.exists) {
        transaction.delete(likeRef);
        transaction.update(postRef, {'likesCount': max(0, currentLikes - 1)});
      } else {
        transaction.set(likeRef, {'liked': true});
        transaction.update(postRef, {'likesCount': currentLikes + 1});
      }
    });
  }
}
