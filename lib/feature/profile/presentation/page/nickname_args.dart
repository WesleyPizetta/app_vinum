/// Argumentos de rota de `ApplicationRoute.nickname`.
///
/// - Primeiro acesso ([editMode] = `false`, padrão): a tela não pode ser
///   fechada (só oferece sair da conta) e, ao salvar, segue o fluxo normal
///   (quiz de onboarding, se pendente, ou home).
/// - Edição ([editMode] = `true`, aberta pelo perfil): pode voltar e, ao
///   salvar, faz `Navigator.pop(context, novoApelido)`.
class NicknameArgs {
  final bool editMode;

  const NicknameArgs({this.editMode = false});
}
