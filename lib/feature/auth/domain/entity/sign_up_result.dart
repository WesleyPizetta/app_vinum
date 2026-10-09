import 'user.dart';

/// Resultado do cadastro.
///
/// Quando o Supabase exige confirmação de e-mail, o cadastro é criado mas
/// **nenhuma sessão** é devolvida: o usuário só pode entrar depois de clicar
/// no link recebido por e-mail.
class SignUpResult {
  final User user;
  final bool requiresEmailConfirmation;

  const SignUpResult({
    required this.user,
    required this.requiresEmailConfirmation,
  });
}
