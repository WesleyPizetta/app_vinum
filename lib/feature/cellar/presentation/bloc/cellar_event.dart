sealed class CellarEvent {}

/// Carrega a primeira página. Também serve de "tentar novamente" no estado
/// de erro.
class CellarStarted extends CellarEvent {}

/// Pede a próxima página (scroll perto do fim ou "tentar novamente" no
/// rodapé). Ignorado se já estiver carregando ou se não houver mais itens.
class CellarLoadMoreRequested extends CellarEvent {}

/// Pull-to-refresh (ou volta do detalhe do vinho): recarrega do offset 0
/// mantendo a lista na tela.
class CellarRefreshed extends CellarEvent {}
