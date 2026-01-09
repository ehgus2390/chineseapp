import 'package:cloud_firestore/cloud_firestore.dart';

class Profile {
  final String id;
  final String name;
  final int age;
  final String occupation;
  final String country;
  final List<String> interests;
  final String gender; // 'male' | 'female'
  final List<String> languages;
  final String bio;
  final String? photoUrl;
  final double distanceKm;
  final GeoPoint? location;

  Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.occupation,
    required this.country,
    required this.interests,
    required this.gender,
    required this.languages,
    required this.bio,
    required this.photoUrl,
    required this.distanceKm,
    required this.location,
  });

  factory Profile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Profile.fromMap(doc.id, data);
  }

  factory Profile.fromMap(String id, Map<String, dynamic> data) {
    final Object? photoValue = data['photoUrl'];
    final String? photoUrl = photoValue is String && photoValue.trim().isNotEmpty
        ? photoValue
        : null;
    final Object? ageValue = data['age'];
    final int age = ageValue is num ? ageValue.toInt() : 0;
    final Object? distanceValue = data['distanceKm'];
    final double distanceKm = distanceValue is num ? distanceValue.toDouble() : 30.0;
    final Object? locationValue = data['location'];
    final GeoPoint? location = locationValue is GeoPoint ? locationValue : null;
    final Object? interestsValue = data['interests'];
    final List<String> interests = interestsValue is List
        ? interestsValue.map((e) => e.toString()).toList()
        : <String>[];
    final Object? languagesValue = data['languages'];
    final List<String> languages = languagesValue is List
        ? languagesValue.map((e) => e.toString()).toList()
        : <String>[];
    return Profile(
      id: id,
      name: (data['name'] ?? '').toString(),
      age: age,
      occupation: (data['occupation'] ?? '').toString(),
      country: (data['country'] ?? '').toString(),
      interests: interests,
      gender: (data['gender'] ?? '').toString(),
      languages: languages,
      bio: (data['bio'] ?? '').toString(),
      photoUrl: photoUrl,
      distanceKm: distanceKm,
      location: location,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'age': age,
      'occupation': occupation,
      'country': country,
      'interests': interests,
      'gender': gender,
      'languages': languages,
      'bio': bio,
      'photoUrl': photoUrl,
      'distanceKm': distanceKm,
      'location': location,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
