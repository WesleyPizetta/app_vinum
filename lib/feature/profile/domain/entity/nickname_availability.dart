/// Resultado de `GET /v1/nicknames/check`.
class NicknameAvailability {
  /// Apelido normalizado (minúsculo, sem "@").
  final String nickname;
  final bool available;

  /// Motivo quando indisponível (ex.: `NICKNAME_TAKEN`). Ver
  /// `NicknameFailureCode`.
  final String? code;

  const NicknameAvailability({
    required this.nickname,
    required this.available,
    this.code,
  });

  @override
  bool operator ==(Object other) =>
      other is NicknameAvailability &&
      other.nickname == nickname &&
      other.available == available &&
      other.code == code;

  @override
  int get hashCode => Object.hash(nickname, available, code);

  @override
  String toString() =>
      'NicknameAvailability(nickname: $nickname, available: $available, '
      'code: $code)';
}
