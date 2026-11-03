import 'package:flutter_test/flutter_test.dart';
import 'package:vinum/feature/profile/domain/entity/nickname_failure_code.dart';
import 'package:vinum/feature/profile/domain/nickname_rules.dart';

void main() {
  group('NicknameRules.normalize', () {
    test('remove "@" inicial, espaços nas pontas e passa para minúsculas', () {
      expect(NicknameRules.normalize('  @Wes_Pizetta '), 'wes_pizetta');
      expect(NicknameRules.normalize('wes'), 'wes');
      expect(NicknameRules.normalize('@'), '');
      expect(NicknameRules.normalize(''), '');
    });

    test('remove só um "@" inicial', () {
      expect(NicknameRules.normalize('@@wes'), '@wes');
    });
  });

  group('NicknameRules.validate', () {
    test('aceita apelidos válidos', () {
      for (final nickname in [
        'wes',
        'wes_pizetta',
        'wes.pizetta',
        'w3s',
        '_wes_',
        'a12',
        'abcdefghijklmnopqrst', // 20
      ]) {
        expect(NicknameRules.validate(nickname), isNull, reason: nickname);
      }
    });

    test('obrigatório', () {
      expect(NicknameRules.validate(''), NicknameFailureCode.required);
    });

    test('tamanho mínimo e máximo', () {
      expect(NicknameRules.validate('ab'), NicknameFailureCode.tooShort);
      expect(
        NicknameRules.validate('abcdefghijklmnopqrstu'), // 21
        NicknameFailureCode.tooLong,
      );
    });

    test('caracteres inválidos', () {
      for (final nickname in ['wes pizetta', 'wés', 'wes-p', 'Wes', 'wes@x']) {
        expect(
          NicknameRules.validate(nickname),
          NicknameFailureCode.invalidChars,
          reason: nickname,
        );
      }
    });

    test('formato: pontos nas pontas, ".." e sem letras', () {
      for (final nickname in ['.wes', 'wes.', 'we..s', '123', '1_2', '___']) {
        expect(
          NicknameRules.validate(nickname),
          NicknameFailureCode.invalidFormat,
          reason: nickname,
        );
      }
    });

    test('isValid normaliza antes de validar', () {
      expect(NicknameRules.isValid('@Wes_Pizetta'), isTrue);
      expect(NicknameRules.isValid('@wes pizetta'), isFalse);
    });
  });

  group('NicknameRules.sanitizeInput', () {
    test('minúsculas, sem acentos, espaços ou símbolos', () {
      expect(NicknameRules.sanitizeInput('João Silva'), 'joaosilva');
      expect(NicknameRules.sanitizeInput('@Wes_Pizetta!'), 'wes_pizetta');
      expect(NicknameRules.sanitizeInput('ação.123'), 'acao.123');
      expect(NicknameRules.sanitizeInput('çÑÜ'), 'cnu');
    });
  });

  group('NicknameRules.suggestFromName', () {
    test('usa o primeiro nome sem acentos', () {
      expect(NicknameRules.suggestFromName('João Silva'), 'joao');
      expect(NicknameRules.suggestFromName('  Ângela  Maria '), 'angela');
      expect(NicknameRules.suggestFromName('wes'), 'wes');
    });

    test('descarta caracteres inválidos', () {
      expect(NicknameRules.suggestFromName("D'Ávila Souza"), 'davila');
      expect(NicknameRules.suggestFromName('Zé-Maria'), 'zemaria');
    });

    test('primeiro nome curto: junta com o último', () {
      expect(NicknameRules.suggestFromName('Li Wu'), 'li_wu');
      expect(NicknameRules.suggestFromName('Zé da Silva'), 'ze_silva');
    });

    test('e-mail: usa a parte antes do "@"', () {
      expect(NicknameRules.suggestFromName('wes.pizetta@gmail.com'),
          'wes.pizetta');
    });

    test('limita a 20 caracteres', () {
      final suggestion =
          NicknameRules.suggestFromName('Maximilianoalexandrederoma Silva');
      expect(suggestion.length, NicknameRules.maxLength);
      expect(NicknameRules.validate(suggestion), isNull);
    });

    test('sem nada aproveitável retorna vazio', () {
      expect(NicknameRules.suggestFromName(null), '');
      expect(NicknameRules.suggestFromName('   '), '');
      expect(NicknameRules.suggestFromName('!!! ???'), '');
    });

    test('a sugestão de um nome comum é válida', () {
      expect(
        NicknameRules.validate(NicknameRules.suggestFromName('João Silva')),
        isNull,
      );
    });
  });
}
