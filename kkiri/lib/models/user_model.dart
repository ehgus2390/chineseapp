import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? displayName;
  final String? searchId;
  final String? photoUrl;
  final String? bio;
  final int? age;
  final String? gender;
  final String? country;
  final List<String>? interests;
  final List<String>? photos;
  final GeoPoint? position;
  final Timestamp? lastSeen;

  UserModel({
    required this.uid,
    this.displayName,
    this.searchId,
    this.photoUrl,
    this.bio,
    this.age,
    this.gender,
    this.country,
    this.interests,
    this.photos,
    this.position,
    this.lastSeen,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception("User data is null!");
    }

    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] as String?,
      searchId: data['searchId'] as String?,
      photoUrl: data['photoUrl'] as String?,
      bio: data['bio'] as String?,
      age: data['age'] as int?,
      gender: data['gender'] as String?,
      country: data['country'] as String?,
      interests: (data['interests'] as List<dynamic>?)?.cast<String>(),
      photos: (data['photos'] as List<dynamic>?)?.cast<String>(),
      position: data['position']?['geopoint'] as GeoPoint?,
      lastSeen: data['lastSeen'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (displayName != null) 'displayName': displayName,
      if (searchId != null) 'searchId': searchId,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (bio != null) 'bio': bio,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (country != null) 'country': country,
      if (interests != null) 'interests': interests,
      if (photos != null) 'photos': photos,
      if (lastSeen != null) 'lastSeen': lastSeen,
    };
  }
}
