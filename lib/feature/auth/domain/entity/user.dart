class User {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final bool onboardingCompleted;

  /// Apelido público (@handle, sem "@"), exibido nas avaliações. `null`
  /// quando o usuário ainda não escolheu um.
  final String? nickname;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.onboardingCompleted = false,
    this.nickname,
  });

  bool get hasNickname {
    final value = nickname?.trim();
    return value != null && value.isNotEmpty;
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    bool? onboardingCompleted,
    String? nickname,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      nickname: nickname ?? this.nickname,
    );
  }
}
