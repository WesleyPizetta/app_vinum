/// Tópicos do conteúdo educativo "Aprenda sobre vinhos".
///
/// O conteúdo é estático e vem do i18n (chaves `learn_<tópico>_*`); veja
/// [LearnTopicContent]. Os nomes do enum são usados por outras telas (ex.:
/// atalhos "o que é isso?" no detalhe do vinho): não renomeie.
enum LearnTopic { body, acidity, tannins, types, pairing, vintage, grapes }

/// Chaves i18n do conteúdo de cada [LearnTopic].
///
/// Para um tópico `body`, por exemplo:
/// - `learn_body_title`: título curto ("Corpo");
/// - `learn_body_summary`: uma linha para o card;
/// - `learn_body_intro`: parágrafo de introdução;
/// - `learn_body_point_1` … `learn_body_point_N`: tópicos/exemplos;
/// - `learn_body_tip`: dica prática ("Na prática").
extension LearnTopicContent on LearnTopic {
  String get titleKey => 'learn_${name}_title';

  String get summaryKey => 'learn_${name}_summary';

  String get introKey => 'learn_${name}_intro';

  String get tipKey => 'learn_${name}_tip';

  /// Quantidade de tópicos (`learn_<tópico>_point_<n>`) no i18n.
  int get pointCount => switch (this) {
        LearnTopic.body => 4,
        LearnTopic.acidity => 4,
        LearnTopic.tannins => 5,
        LearnTopic.types => 5,
        LearnTopic.pairing => 5,
        LearnTopic.vintage => 4,
        LearnTopic.grapes => 6,
      };

  List<String> get pointKeys => List<String>.generate(
        pointCount,
        (index) => 'learn_${name}_point_${index + 1}',
        growable: false,
      );
}
