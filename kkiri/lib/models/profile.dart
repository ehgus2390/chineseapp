class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.languages,
    required this.bio,
    required this.avatarUrl,
    required this.statusMessage,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final List<String> languages;
  final String bio;
  final String avatarUrl;
  final String statusMessage;
  final double latitude;
  final double longitude;

  Profile copyWith({
    String? statusMessage,
    String? avatarUrl,
  }) {
    return Profile(
      id: id,
      name: name,
      languages: languages,
      bio: bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      statusMessage: statusMessage ?? this.statusMessage,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
