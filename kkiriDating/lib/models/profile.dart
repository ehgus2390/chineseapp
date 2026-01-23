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
  final bool notificationsEnabled;

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
    required this.notificationsEnabled,
  });

  factory Profile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Profile.fromMap(doc.id, data);
  }

  factory Profile.fromMap(String id, Map<String, dynamic> data) {
    final Object? photoValue = data['photoUrl'];
    final String? photoUrl =
        photoValue is String && photoValue.trim().isNotEmpty
        ? photoValue
        : null;
    final Object? ageValue = data['age'];
    final int age = ageValue is num ? ageValue.toInt() : 0;
    final Object? distanceValue = data['distanceKm'];
    final double distanceKm = distanceValue is num
        ? distanceValue.toDouble()
        : 30.0;
    final Object? locationValue = data['location'];
    final GeoPoint? location = locationValue is GeoPoint ? locationValue : null;
    final Object? interestsValue = data['interests'];
    final List<String> interests = interestsValue is List
        ? interestsValue.whereType<String>().toList()
        : <String>[];
    final Object? languagesValue = data['languages'];
    final List<String> languages = languagesValue is List
        ? languagesValue.whereType<String>().toList()
        : <String>[];
    final Object? notificationsValue = data['notificationsEnabled'];
    final bool notificationsEnabled = notificationsValue is bool
        ? notificationsValue
        : true;
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
      notificationsEnabled: notificationsEnabled,
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
      'notificationsEnabled': notificationsEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Profile copyWith({
    String? id,
    String? name,
    int? age,
    String? occupation,
    String? country,
    List<String>? interests,
    String? gender,
    List<String>? languages,
    String? bio,
    String? photoUrl,
    double? distanceKm,
    GeoPoint? location,
    bool? notificationsEnabled,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      occupation: occupation ?? this.occupation,
      country: country ?? this.country,
      interests: interests ?? this.interests,
      gender: gender ?? this.gender,
      languages: languages ?? this.languages,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      distanceKm: distanceKm ?? this.distanceKm,
      location: location ?? this.location,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  static Profile merge(Profile base, Map<String, dynamic> updates) {
    final Object? interestsValue = updates['interests'];
    final List<String>? interests = interestsValue is List
        ? _normalizeStringList(interestsValue)
        : null;
    final Object? languagesValue = updates['languages'];
    final List<String>? languages = languagesValue is List
        ? _normalizeStringList(languagesValue)
        : null;
    final Object? ageValue = updates['age'];
    final int? age = ageValue is num ? ageValue.toInt() : null;
    final Object? distanceValue = updates['distanceKm'];
    final double? distanceKm = distanceValue is num
        ? distanceValue.toDouble()
        : null;
    final Object? locationValue = updates['location'];
    final GeoPoint? location = locationValue is GeoPoint ? locationValue : null;
    final Object? notificationsValue = updates['notificationsEnabled'];
    final bool? notificationsEnabled = notificationsValue is bool
        ? notificationsValue
        : null;
    final Object? photoValue = updates['photoUrl'];
    final String? photoUrl = photoValue is String && photoValue.trim().isNotEmpty
        ? photoValue
        : (photoValue is String ? null : null);

    return base.copyWith(
      id: updates['id']?.toString(),
      name: updates['name']?.toString(),
      age: age,
      occupation: updates['occupation']?.toString(),
      country: updates['country']?.toString(),
      interests: interests,
      gender: updates['gender']?.toString(),
      languages: languages,
      bio: updates['bio']?.toString(),
      photoUrl: photoUrl,
      distanceKm: distanceKm,
      location: location,
      notificationsEnabled: notificationsEnabled,
    );
  }

  static List<String> _normalizeStringList(List<dynamic> values) {
    return values.whereType<String>().where((v) => v.isNotEmpty).toList();
  }
}
