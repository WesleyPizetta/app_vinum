import 'dart:convert';

/// Helpers defensivos para ler respostas do BFF.
///
/// O `JsonConverter` do Chopper só decodifica o corpo quando o header
/// `Content-Type` é `application/json`; caso contrário `response.body` chega
/// como `String`. Estas funções aceitam as duas formas.
class JsonUtils {
  JsonUtils._();

  /// Decodifica [raw] se vier como `String` JSON; caso contrário devolve como
  /// está. Retorna `null` para strings vazias ou JSON inválido.
  static dynamic decode(dynamic raw) {
    if (raw is! String) return raw;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    try {
      return jsonDecode(trimmed);
    } on FormatException {
      return null;
    }
  }

  static Map<String, dynamic>? asMap(dynamic value) {
    final decoded = decode(value);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, v) => MapEntry(key.toString(), v));
    }
    return null;
  }

  static List<dynamic>? asList(dynamic value) {
    final decoded = decode(value);
    return decoded is List ? decoded : null;
  }

  /// Aceita `int`, `num` inteiro (ex.: `3.0`) ou `String` numérica.
  static int? readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) {
      return value.isFinite && value == value.truncateToDouble()
          ? value.toInt()
          : null;
    }
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double? readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  /// String não vazia (após trim), ou `null`.
  static String? readString(dynamic value) {
    if (value is! String) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static bool? readBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    return null;
  }

  /// Lista de strings não vazias. Itens que não são `String` (ou são vazios)
  /// são descartados; retorna lista vazia quando [value] não é uma lista.
  static List<String> readStringList(dynamic value) {
    final list = asList(value);
    if (list == null) return const [];
    return list
        .map(readString)
        .whereType<String>()
        .toList(growable: false);
  }

  /// Extrai o código de `{"error": "...", "code": "..."}` de um corpo de erro.
  static String? readErrorCode(dynamic rawError) =>
      readString(asMap(rawError)?['code']);

  /// Extrai a mensagem de `{"error": "..."}` de um corpo de erro.
  static String? readErrorMessage(dynamic rawError) {
    final map = asMap(rawError);
    if (map != null) {
      return readString(map['error']) ?? readString(map['message']);
    }
    return readString(rawError);
  }
}
