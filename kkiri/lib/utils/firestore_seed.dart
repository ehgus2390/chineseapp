// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart';
// import '../firebase_options.dart';
//
// /// Firestore 자동 시드 스크립트
// Future<void> seedFirestore() async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   final db = FirebaseFirestore.instance;
//
//   print('🚀 Firestore 자동 시드 시작...');
//
//   // ----------------------------
//   // 1️⃣ USERS (3명)
//   // ----------------------------
//   final users = [
//     {
//       'uid': 'user_001',
//       'displayName': 'Tony',
//       'searchId': 'tony123',
//       'photoUrl':
//       'https://randomuser.me/api/portraits/men/11.jpg',
//       'bio': 'Exchange student from the US 🇺🇸',
//       'language': 'en',
//       'interests': ['travel', 'music', 'culture'],
//       'position': {
//         'geohash': 'wydmvh3n6',
//         'geopoint': const GeoPoint(37.5665, 126.9780),
//       },
//       'updatedAt': FieldValue.serverTimestamp(),
//     },
//     {
//       'uid': 'user_002',
//       'displayName': 'Yuna',
//       'searchId': 'yuna_k',
//       'photoUrl':
//       'https://randomuser.me/api/portraits/women/18.jpg',
//       'bio': '한국에서 온 교환학생 ✨',
//       'language': 'ko',
//       'interests': ['fashion', 'food', 'study'],
//       'position': {
//         'geohash': 'wydmvh3m9',
//         'geopoint': const GeoPoint(37.5700, 126.9765),
//       },
//       'updatedAt': FieldValue.serverTimestamp(),
//     },
//     {
//       'uid': 'user_003',
//       'displayName': 'Ravi',
//       'searchId': 'ravi_in',
//       'photoUrl':
//       'https://randomuser.me/api/portraits/men/31.jpg',
//       'bio': 'Namaste! I love K-dramas 🇮🇳',
//       'language': 'hi',
//       'interests': ['movies', 'language exchange'],
//       'position': {
//         'geohash': 'wydmvh4k9',
//         'geopoint': const GeoPoint(37.5670, 126.9800),
//       },
//       'updatedAt': FieldValue.serverTimestamp(),
//     },
//   ];
//
//   for (final u in users) {
//     await db.collection('users').doc(u['uid']).set(u);
//   }
//   print('✅ users 3명 추가 완료');
//
//   // ----------------------------
//   // 2️⃣ POSTS (2개)
//   // ----------------------------
//   final posts = [
//     {
//       'authorId': 'user_001',
//       'text': '오늘 명동 다녀왔어요! 🇰🇷 음식이 정말 맛있네요 😋',
//       'imageUrl': 'https://picsum.photos/400/300?1',
//       'tags': ['travel', 'food'],
//       'likesCount': 2,
//       'commentsCount': 1,
//       'isPopular': false,
//       'createdAt': FieldValue.serverTimestamp(),
//     },
//     {
//       'authorId': 'user_002',
//       'text': '내일 홍대에서 밋업 어때요? 🧋',
//       'imageUrl': 'https://picsum.photos/400/300?2',
//       'tags': ['meetup', 'friends'],
//       'likesCount': 0,
//       'commentsCount': 0,
//       'isPopular': false,
//       'createdAt': FieldValue.serverTimestamp(),
//     },
//   ];
//
//   for (final p in posts) {
//     final ref = await db.collection('posts').add(p);
//     await db
//         .collection('posts')
//         .doc(ref.id)
//         .collection('likes')
//         .doc('user_002')
//         .set({'likedAt': FieldValue.serverTimestamp()});
//     await db
//         .collection('posts')
//         .doc(ref.id)
//         .collection('comments')
//         .add({
//       'authorId': 'user_003',
//       'text': 'I want to join next time!',
//       'createdAt': FieldValue.serverTimestamp(),
//     });
//   }
//   print('✅ posts 2개 추가 완료');
//
//   // ----------------------------
//   // 3️⃣ CHATS (1개)
//   // ----------------------------
//   final chatRoomId = 'user_001_user_002';
//   final chatRef = db.collection('chats').doc(chatRoomId);
//
//   await chatRef.set({
//     'users': ['user_001', 'user_002'],
//     'lastMessage': 'See you tomorrow!',
//     'updatedAt': FieldValue.serverTimestamp(),
//   });
//
//   await chatRef.collection('messages').add({
//     'senderId': 'user_001',
//     'receiverId': 'user_002',
//     'text': 'Hi Yuna! Are you free tomorrow?',
//     'createdAt': FieldValue.serverTimestamp(),
//     'isRead': true,
//   });
//
//   await chatRef.collection('messages').add({
//     'senderId': 'user_002',
//     'receiverId': 'user_001',
//     'text': 'Sure! Let’s meet at Hongdae 🍰',
//     'createdAt': FieldValue.serverTimestamp(),
//     'isRead': false,
//   });
//
//   print('✅ chats 샘플 추가 완료');
//   print('🎉 Firestore 시드 완료!');
// }
