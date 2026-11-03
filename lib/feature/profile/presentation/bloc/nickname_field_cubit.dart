import 'dart:async';

import 'package:essentials/essentials.dart';

import '../../domain/entity/nickname_availability.dart';
import '../../domain/entity/nickname_failure_code.dart';
import '../../domain/nickname_rules.dart';
import '../../domain/usecase/check_nickname_availability.dart';
import 'nickname_field_state.dart';

/// Estado do campo de apelido: validação local imediata + verificação de
/// disponibilidade no servidor com debounce.
///
/// Respostas antigas (de um texto que já mudou) são descartadas.
class NicknameFieldCubit extends Cubit<NicknameFieldState> {
  static const Duration defaultDebounce = Duration(milliseconds: 500);

  final CheckNicknameAvailability _checkAvailability;
  final Duration _debounce;

  Timer? _debounceTimer;

  /// Incrementado a cada mudança; uma resposta só vale se o id dela ainda
  /// for o atual.
  int _requestId = 0;

  /// Apelido atual do usuário (modo edição): disponível sem consultar.
  String? _ownNickname;

  NicknameFieldCubit(
    this._checkAvailability, {
    Duration debounce = defaultDebounce,
  })  : _debounce = debounce,
        super(const NicknameFieldState());

  /// Define o valor inicial do campo (ex.: sugestão a partir do nome ou o
  /// apelido atual) e o apelido atual do usuário, se houver.
  void start({String initial = '', String? ownNickname}) {
    final own = ownNickname == null ? '' : NicknameRules.normalize(ownNickname);
    _ownNickname = own.isEmpty ? null : own;
    changed(initial, force: true);
  }

  /// Texto do campo mudou. [force] reavalia mesmo sem mudança.
  void changed(String raw, {bool force = false}) {
    final nickname = NicknameRules.normalize(raw);
    // Mesmo texto (ex.: só mudou o cursor): não refaz a consulta, exceto
    // para tentar de novo após erro de rede.
    if (!force &&
        nickname == state.nickname &&
        state.status != NicknameFieldStatus.error &&
        state.status != NicknameFieldStatus.empty) {
      return;
    }

    _debounceTimer?.cancel();
    final requestId = ++_requestId;

    if (nickname.isEmpty) {
      const emptyState = NicknameFieldState();
      if (state != emptyState) emit(emptyState);
      return;
    }

    final localError = NicknameRules.validate(nickname);
    if (localError != null) {
      emit(NicknameFieldState(
        nickname: nickname,
        status: NicknameFieldStatus.invalid,
        errorCode: localError,
      ));
      return;
    }

    if (nickname == _ownNickname) {
      emit(NicknameFieldState(
        nickname: nickname,
        status: NicknameFieldStatus.available,
      ));
      return;
    }

    emit(NicknameFieldState(
      nickname: nickname,
      status: NicknameFieldStatus.checking,
    ));
    _debounceTimer = Timer(_debounce, () => _check(nickname, requestId));
  }

  /// Tentativa de envio: campo vazio passa a mostrar "obrigatório".
  void submitAttempted() {
    if (state.status == NicknameFieldStatus.empty) {
      _requestId++;
      emit(const NicknameFieldState(
        status: NicknameFieldStatus.invalid,
        errorCode: NicknameFailureCode.required,
      ));
    }
  }

  /// O servidor recusou [nickname] ao salvar (ex.: 409 em uso, corrida com
  /// outro usuário). Só aplica se o campo ainda mostra esse apelido.
  void rejectedByServer(String nickname, String code) {
    final normalized = NicknameRules.normalize(nickname);
    if (normalized != state.nickname) return;
    _debounceTimer?.cancel();
    _requestId++;
    emit(NicknameFieldState(
      nickname: normalized,
      status: NicknameFieldStatus.unavailable,
      errorCode: code,
    ));
  }

  Future<void> _check(String nickname, int requestId) async {
    Try<NicknameAvailability> result;
    try {
      result = await _checkAvailability(nickname);
    } catch (e) {
      result = Try.reject(UnknownFailure(e));
    }
    if (isClosed || requestId != _requestId) return; // resposta antiga

    result.fold(
      (failure) {
        final code = failure.code;
        if (NicknameFailureCode.isRuleViolation(code)) {
          emit(NicknameFieldState(
            nickname: nickname,
            status: NicknameFieldStatus.unavailable,
            errorCode: code,
          ));
        } else {
          emit(NicknameFieldState(
            nickname: nickname,
            status: NicknameFieldStatus.error,
            errorCode: code == null || code == 'UNKNOWN'
                ? NicknameFailureCode.network
                : code,
          ));
        }
      },
      (availability) => emit(NicknameFieldState(
        nickname: nickname,
        status: availability.available
            ? NicknameFieldStatus.available
            : NicknameFieldStatus.unavailable,
        errorCode: availability.available
            ? null
            : (availability.code ?? NicknameFailureCode.taken),
      )),
    );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
