enum NicknameFieldStatus {
  /// Campo vazio e ainda sem tentativa de envio (sem erro na tela).
  empty,

  /// Violação de regra local (ver [NicknameFieldState.errorCode]).
  invalid,

  /// Aguardando o debounce ou a resposta do servidor.
  checking,

  /// Servidor confirmou que está disponível.
  available,

  /// Servidor recusou (em uso, reservado, ofensivo...).
  unavailable,

  /// Não foi possível verificar (rede/servidor).
  error,
}

class NicknameFieldState {
  /// Apelido normalizado (minúsculo, sem "@").
  final String nickname;
  final NicknameFieldStatus status;

  /// Código de `NicknameFailureCode` quando [status] é `invalid`,
  /// `unavailable` ou `error`.
  final String? errorCode;

  const NicknameFieldState({
    this.nickname = '',
    this.status = NicknameFieldStatus.empty,
    this.errorCode,
  });

  /// Pode ser enviado: válido localmente e confirmado pelo servidor.
  bool get isAvailable => status == NicknameFieldStatus.available;

  bool get isChecking => status == NicknameFieldStatus.checking;

  bool get hasError =>
      status == NicknameFieldStatus.invalid ||
      status == NicknameFieldStatus.unavailable ||
      status == NicknameFieldStatus.error;

  @override
  bool operator ==(Object other) =>
      other is NicknameFieldState &&
      other.nickname == nickname &&
      other.status == status &&
      other.errorCode == errorCode;

  @override
  int get hashCode => Object.hash(nickname, status, errorCode);

  @override
  String toString() =>
      'NicknameFieldState($nickname, $status, errorCode: $errorCode)';
}
