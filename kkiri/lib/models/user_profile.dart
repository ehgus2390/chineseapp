class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? avatarUrl;
  final List<String> languages;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.languages,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'avatarUrl': avatarUrl,
    'languages': languages,
  };

  factory UserProfile.fromMap(String uid, Map<String, dynamic> m) {
    return UserProfile(
      uid: uid,
      name: (m['name'] ?? '') as String,
      email: (m['email'] ?? '') as String,
      avatarUrl: m['avatarUrl'] as String?,
      languages: (m['languages'] as List?)?.cast<String>() ?? const ['ko', 'en'],
    );
  }
}
