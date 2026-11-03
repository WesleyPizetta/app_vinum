abstract class RegisterEvent {}

class RegisterSubmitted extends RegisterEvent {
  final String name;
  final String email;
  final String password;

  /// Apelido (@handle) escolhido; pode vir com "@" ou maiúsculas
  /// (normalizado pelo bloc).
  final String nickname;

  RegisterSubmitted({
    required this.name,
    required this.email,
    required this.password,
    required this.nickname,
  });
}
