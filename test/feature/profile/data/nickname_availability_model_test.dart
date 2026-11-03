import 'package:flutter_test/flutter_test.dart';
import 'package:vinum/feature/profile/data/model/nickname_availability_model.dart';
import 'package:vinum/feature/profile/domain/entity/nickname_availability.dart';

void main() {
  group('NicknameAvailabilityModel.tryParse', () {
    test('disponível', () {
      expect(
        NicknameAvailabilityModel.tryParse(
          {'nickname': 'wes_pizetta', 'available': true},
        ),
        const NicknameAvailability(nickname: 'wes_pizetta', available: true),
      );
    });

    test('indisponível com código', () {
      expect(
        NicknameAvailabilityModel.tryParse({
          'nickname': 'admin',
          'available': false,
          'code': 'NICKNAME_RESERVED',
        }),
        const NicknameAvailability(
          nickname: 'admin',
          available: false,
          code: 'NICKNAME_RESERVED',
        ),
      );
    });

    test('aceita o corpo como String JSON', () {
      expect(
        NicknameAvailabilityModel.tryParse(
          '{"nickname":"wes","available":false,"code":"NICKNAME_TAKEN"}',
        ),
        const NicknameAvailability(
          nickname: 'wes',
          available: false,
          code: 'NICKNAME_TAKEN',
        ),
      );
    });

    test('sem nickname no corpo usa o pedido; ignora code quando disponível',
        () {
      expect(
        NicknameAvailabilityModel.tryParse(
          {'available': true, 'code': 'X'},
          requestedNickname: 'wes',
        ),
        const NicknameAvailability(nickname: 'wes', available: true),
      );
    });

    test('retorna null fora do contrato', () {
      expect(NicknameAvailabilityModel.tryParse(null), isNull);
      expect(NicknameAvailabilityModel.tryParse('not json'), isNull);
      expect(NicknameAvailabilityModel.tryParse([1, 2]), isNull);
      expect(NicknameAvailabilityModel.tryParse({'nickname': 'wes'}), isNull);
      expect(
        NicknameAvailabilityModel.tryParse(
            {'nickname': 'wes', 'available': 'talvez'}),
        isNull,
      );
    });
  });

  group('NicknameModel.readNickname', () {
    test('lê o apelido salvo', () {
      expect(NicknameModel.readNickname({'nickname': 'wes_pizetta'}),
          'wes_pizetta');
      expect(NicknameModel.readNickname('{"nickname":"wes"}'), 'wes');
    });

    test('ausente ou vazio -> null', () {
      expect(NicknameModel.readNickname({}), isNull);
      expect(NicknameModel.readNickname({'nickname': ''}), isNull);
      expect(NicknameModel.readNickname(null), isNull);
    });
  });
}
