/// User profile. Mirrors ProfileResponse from the backend.
class Profile {
  final String id;
  final String? username;
  final String? userBio;
  final String? generatedBio;
  final String? avatarUrl;

  const Profile({
    required this.id,
    this.username,
    this.userBio,
    this.generatedBio,
    this.avatarUrl,
  });

  /// The bio to show: the AI-generated knowledge identity wins, else the user's own.
  String? get displayBio => generatedBio ?? userBio;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'].toString(),
        username: json['username'],
        userBio: json['user_bio'],
        generatedBio: json['generated_bio'],
        avatarUrl: json['avatar_url'],
      );
}
