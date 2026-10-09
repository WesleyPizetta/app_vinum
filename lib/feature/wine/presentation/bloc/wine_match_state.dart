import '../../../home/domain/entity/wine_match.dart';

/// Estado da seção "Por que este vinho combina com você?" do detalhe.
/// Separado do `WineDetailBloc` para que falhas aqui nunca afetem a página.
sealed class WineMatchState {}

class WineMatchInitial extends WineMatchState {}

class WineMatchLoading extends WineMatchState {}

class WineMatchLoaded extends WineMatchState {
  final WineMatch match;

  WineMatchLoaded({required this.match});
}

/// Sem quiz (409), vinho não encontrado, sessão inválida ou resposta
/// inesperada: a seção fica oculta.
class WineMatchHidden extends WineMatchState {}

/// Falha de conexão: a seção mostra um "tentar novamente" discreto.
class WineMatchError extends WineMatchState {}
