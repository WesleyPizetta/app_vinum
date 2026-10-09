/// Cache em memória atrelado à sessão do usuário autenticado.
///
/// Implementações são limpas pelo usecase `Logout` (inclusive no fluxo de
/// sessão expirada/401), para que dados de um usuário não vazem para o
/// próximo login.
abstract class SessionCache {
  void clear();
}
