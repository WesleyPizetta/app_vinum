import '../../domain/entity/onboarding_question.dart';
import '../../../../core/utils/json_utils.dart';

class OnboardingOptionModel {
  final int id;
  final String label;

  const OnboardingOptionModel({required this.id, required this.label});

  /// Retorna `null` se o JSON não seguir o contrato.
  static OnboardingOptionModel? tryParse(dynamic json) {
    final map = JsonUtils.asMap(json);
    if (map == null) return null;
    final id = JsonUtils.readInt(map['id']);
    final label = JsonUtils.readString(map['label']);
    if (id == null || label == null) return null;
    return OnboardingOptionModel(id: id, label: label);
  }

  OnboardingOption toEntity() => OnboardingOption(id: id, label: label);
}

class OnboardingQuestionModel {
  final int id;
  final String title;

  /// Opcional: pode vir ausente, `null` ou vazio (tratado como ausente).
  final String? funFact;
  final List<OnboardingOptionModel> options;

  const OnboardingQuestionModel({
    required this.id,
    required this.title,
    this.funFact,
    required this.options,
  });

  /// Retorna `null` se a pergunta ou qualquer opção for inválida, ou se não
  /// houver opções — o backend exige resposta para todas as perguntas, então
  /// uma pergunta sem opção válida deixaria o usuário sem conseguir enviar.
  static OnboardingQuestionModel? tryParse(dynamic json) {
    final map = JsonUtils.asMap(json);
    if (map == null) return null;
    final id = JsonUtils.readInt(map['id']);
    final title = JsonUtils.readString(map['title']);
    final rawOptions = JsonUtils.asList(map['options']);
    if (id == null || title == null || rawOptions == null) return null;

    final options = <OnboardingOptionModel>[];
    for (final rawOption in rawOptions) {
      final option = OnboardingOptionModel.tryParse(rawOption);
      if (option == null) return null;
      options.add(option);
    }
    if (options.isEmpty) return null;

    return OnboardingQuestionModel(
      id: id,
      title: title,
      funFact: JsonUtils.readString(map['fun_fact']),
      options: options,
    );
  }

  /// Faz o parse de `{"total_questions": int, "questions": [...]}`.
  /// Retorna `null` se o corpo não seguir o contrato.
  static List<OnboardingQuestionModel>? tryParseQuiz(dynamic body) {
    final map = JsonUtils.asMap(body);
    if (map == null) return null;
    final rawQuestions = JsonUtils.asList(map['questions']);
    if (rawQuestions == null) return null;

    final questions = <OnboardingQuestionModel>[];
    for (final rawQuestion in rawQuestions) {
      final question = OnboardingQuestionModel.tryParse(rawQuestion);
      if (question == null) return null;
      questions.add(question);
    }
    return questions;
  }

  OnboardingQuestion toEntity() => OnboardingQuestion(
        id: id,
        title: title,
        funFact: funFact,
        options: options.map((o) => o.toEntity()).toList(growable: false),
      );
}
