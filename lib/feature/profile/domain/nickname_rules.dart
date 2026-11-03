import 'entity/nickname_failure_code.dart';

/// Regras do apelido (@handle), espelhando o BFF para feedback imediato.
///
/// O servidor continua sendo a autoridade (reservados, ofensivos e em uso só
/// são conhecidos por ele).
///
/// - guardado em minúsculas; a entrada pode começar com "@" (removido);
/// - 3 a 20 caracteres;
/// - apenas `[a-z0-9_.]`;
/// - não pode começar/terminar com "." nem conter "..";
/// - precisa ter pelo menos uma letra.
class NicknameRules {
  NicknameRules._();

  static const int minLength = 3;
  static const int maxLength = 20;

  static final RegExp _allowed = RegExp(r'^[a-z0-9_.]+$');
  static final RegExp _disallowedChar = RegExp(r'[^a-z0-9_.]');
  static final RegExp _letter = RegExp(r'[a-z]');
  static final RegExp _repeatedDots = RegExp(r'\.{2,}');
  static final RegExp _edgeDots = RegExp(r'^\.+|\.+$');
  static final RegExp _whitespace = RegExp(r'\s+');

  static const String _accented = 'àáâãäåāçèéêëēìíîïīñòóôõöøōùúûüūýÿ';
  static const String _plain = 'aaaaaaaceeeeeiiiiinooooooouuuuuyy';

  /// Normaliza a entrada: remove espaços nas pontas, um "@" inicial e passa
  /// para minúsculas. Não descarta caracteres inválidos (a validação acusa).
  static String normalize(String raw) {
    var value = raw.trim();
    if (value.startsWith('@')) value = value.substring(1);
    return value.trim().toLowerCase();
  }

  /// Valida um apelido **já normalizado** (ver [normalize]). Retorna o código
  /// de [NicknameFailureCode] da primeira regra violada, ou `null` se válido.
  static String? validate(String nickname) {
    if (nickname.isEmpty) return NicknameFailureCode.required;
    if (!_allowed.hasMatch(nickname)) return NicknameFailureCode.invalidChars;
    if (nickname.length < minLength) return NicknameFailureCode.tooShort;
    if (nickname.length > maxLength) return NicknameFailureCode.tooLong;
    if (nickname.startsWith('.') ||
        nickname.endsWith('.') ||
        nickname.contains('..')) {
      return NicknameFailureCode.invalidFormat;
    }
    if (!_letter.hasMatch(nickname)) return NicknameFailureCode.invalidFormat;
    return null;
  }

  /// Atalho: normaliza e valida [raw].
  static bool isValid(String raw) => validate(normalize(raw)) == null;

  /// Troca letras acentuadas minúsculas pela letra base (`"joão"` →
  /// `"joao"`). Aplique depois de `toLowerCase()`.
  static String removeDiacritics(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      final index = _accented.indexOf(char);
      buffer.write(index >= 0 ? _plain[index] : char);
    }
    return buffer.toString();
  }

  /// Filtro aplicado enquanto o usuário digita: minúsculas, sem acentos e
  /// somente `[a-z0-9_.]` (espaços, "@" e outros símbolos são descartados).
  static String sanitizeInput(String value) =>
      removeDiacritics(value.toLowerCase()).replaceAll(_disallowedChar, '');

  /// Sugestão de apelido a partir do nome completo: primeiro nome, sem
  /// acentos e sem caracteres inválidos (`"João Silva"` → `"joao"`).
  ///
  /// Se o primeiro nome for curto demais, junta com o último
  /// (`"Li Wu"` → `"li_wu"`). Se [fullName] for um e-mail, usa a parte antes
  /// do "@". Retorna `""` quando não há nada aproveitável. O resultado pode
  /// ainda ser inválido (ex.: só números); a validação mostra o motivo.
  static String suggestFromName(String? fullName) {
    var name = (fullName ?? '').trim();
    final at = name.indexOf('@');
    if (at >= 0) name = name.substring(0, at);

    final words = name
        .split(_whitespace)
        .map(_cleanWord)
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return '';

    var candidate = words.first;
    if (candidate.length < minLength && words.length > 1) {
      candidate = '${words.first}_${words.last}';
    }
    if (candidate.length > maxLength) {
      candidate = _trimDots(candidate.substring(0, maxLength));
    }
    return candidate;
  }

  static String _cleanWord(String word) =>
      _trimDots(sanitizeInput(word).replaceAll(_repeatedDots, '.'));

  static String _trimDots(String value) => value.replaceAll(_edgeDots, '');
}
