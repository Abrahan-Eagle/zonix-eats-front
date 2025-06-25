class UserProfile {
  final int id;
  final String name;
  final String email;
  final String? role;
  final String? profilePic;
  final bool? completedOnboarding;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.profilePic,
    this.completedOnboarding,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'],
      profilePic: json['profile_pic'],
      completedOnboarding: json['completed_onboarding'],
    );
  }
}
