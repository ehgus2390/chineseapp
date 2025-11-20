import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? displayName;
  final String? searchId;
  final String? photoUrl;
  final String? bio;
  final int? age;
  final String? gender;
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
    this.interests,
    this.photos,
    this.position,
    this.lastSeen,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      return UserModel(uid: doc.id);
    }

    List<String>? _stringList(dynamic value) {
      if (value is Iterable) {
        return value.map((e) => e.toString()).toList();
      }
      return null;
    }

    GeoPoint? _geoPoint(dynamic value) {
      if (value is Map<String, dynamic>) {
        final point = value['geopoint'];
        if (point is GeoPoint) {
          return point;
        }
      }
      return null;
    }

    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] as String?,
      searchId: data['searchId'] as String?,
      photoUrl: data['photoUrl'] as String?,
      bio: data['bio'] as String?,
      age: data['age'] is int ? data['age'] as int : null,
      gender: data['gender'] as String?,
      interests: _stringList(data['interests']),
      photos: _stringList(data['photos']),
      position: _geoPoint(data['position']),
      lastSeen: data['lastSeen'] is Timestamp ? data['lastSeen'] as Timestamp : null,
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
      if (interests != null) 'interests': interests,
      if (photos != null) 'photos': photos,
      if (lastSeen != null) 'lastSeen': lastSeen,
    };
  }
}
