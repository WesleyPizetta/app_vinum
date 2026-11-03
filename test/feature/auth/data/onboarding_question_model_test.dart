import 'package:flutter_test/flutter_test.dart';
import 'package:vinum/feature/auth/data/model/onboarding_question_model.dart';

void main() {
  group('OnboardingQuestionModel.tryParseQuiz', () {
    test('lê fun_fact quando presente e mantém a ordem das opções', () {
      final questions = OnboardingQuestionModel.tryParseQuiz({
        'total_questions': 2,
        'questions': [
          {
            'id': 1,
            'title': 'Café?',
            'fun_fact': 'Taninos lembram o amargor do café.',
            'options': [
              {'id': 12, 'label': 'Forte'},
              {'id': 10, 'label': 'Fraco'},
              {'id': 11, 'label': 'Médio'},
            ],
          },
          {
            'id': 2,
            'title': 'Limão?',
            'options': [
              {'id': 20, 'label': 'Sim'},
              {'id': 21, 'label': 'Não'},
            ],
          },
        ],
      });

      expect(questions, isNotNull);
      final entities = questions!.map((q) => q.toEntity()).toList();
      expect(entities[0].funFact, 'Taninos lembram o amargor do café.');
      expect(entities[0].options.map((o) => o.id), [12, 10, 11]);
      expect(entities[1].funFact, isNull);
    });

    test('fun_fact nulo, vazio ou não-string vira null', () {
      for (final funFact in <dynamic>[null, '', '   ', 42]) {
        final question = OnboardingQuestionModel.tryParse({
          'id': 1,
          'title': 'Pergunta',
          'fun_fact': funFact,
          'options': [
            {'id': 10, 'label': 'A'},
          ],
        });
        expect(question, isNotNull);
        expect(question!.toEntity().funFact, isNull);
      }
    });
  });
}
