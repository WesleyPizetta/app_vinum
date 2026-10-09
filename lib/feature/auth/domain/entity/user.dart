class User {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final bool onboardingCompleted;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.onboardingCompleted = false,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    bool? onboardingCompleted,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
