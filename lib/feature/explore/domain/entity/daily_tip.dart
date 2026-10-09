import 'learn_topic.dart';

/// Uma "Dica do dia": texto curto (chave i18n) e, opcionalmente, o tópico
/// do "Aprenda" que aprofunda o assunto.
class DailyTip {
  /// Chave i18n do texto da dica.
  final String textKey;

  /// Tópico relacionado ("Saiba mais"), se houver.
  final LearnTopic? topic;

  const DailyTip(this.textKey, [this.topic]);

  /// Dicas disponíveis (chaves `learn_tip_<n>`).
  static const List<DailyTip> all = [
    DailyTip('learn_tip_1'),
    DailyTip('learn_tip_2'),
    DailyTip('learn_tip_3'),
    DailyTip('learn_tip_4', LearnTopic.types),
    DailyTip('learn_tip_5', LearnTopic.tannins),
    DailyTip('learn_tip_6', LearnTopic.acidity),
    DailyTip('learn_tip_7', LearnTopic.body),
    DailyTip('learn_tip_8', LearnTopic.vintage),
    DailyTip('learn_tip_9', LearnTopic.pairing),
    DailyTip('learn_tip_10', LearnTopic.grapes),
    DailyTip('learn_tip_11'),
  ];

  /// Dica de [date] (data do calendário local): determinística, troca uma
  /// vez por dia e percorre todas as dicas em sequência.
  static DailyTip forDay(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final daysSinceEpoch = day.difference(DateTime.utc(1970)).inDays;
    return all[daysSinceEpoch % all.length];
  }
}
