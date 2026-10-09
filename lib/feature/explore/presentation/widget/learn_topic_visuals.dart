import 'package:flutter/material.dart';

import '../../domain/entity/learn_topic.dart';

/// Ícone de cada [LearnTopic] (cards e cabeçalho do sheet).
IconData learnTopicIcon(LearnTopic topic) => switch (topic) {
      LearnTopic.body => Icons.water_drop_outlined,
      LearnTopic.acidity => Icons.bolt_outlined,
      LearnTopic.tannins => Icons.grain,
      LearnTopic.types => Icons.wine_bar_outlined,
      LearnTopic.pairing => Icons.restaurant_outlined,
      LearnTopic.vintage => Icons.calendar_month_outlined,
      LearnTopic.grapes => Icons.spa_outlined,
    };

/// Cor de destaque do tópico, derivada do tema (funciona no claro e no
/// escuro).
Color learnTopicAccent(ColorScheme colorScheme, LearnTopic topic) =>
    switch (topic) {
      LearnTopic.body ||
      LearnTopic.tannins ||
      LearnTopic.types ||
      LearnTopic.grapes =>
        colorScheme.primary,
      LearnTopic.acidity ||
      LearnTopic.pairing ||
      LearnTopic.vintage =>
        colorScheme.secondary,
    };
