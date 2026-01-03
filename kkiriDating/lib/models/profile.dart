class Profile {
  final String id;
  final String name;
  final String nationality; // ex) KR, US, JP...
  final List<String> languages; // ex) ['ko','en']
  final String bio;
  final String avatarUrl;

  Profile({
    required this.id,
    required this.name,
    required this.nationality,
    required this.languages,
    required this.bio,
    required this.avatarUrl,
  });
}
