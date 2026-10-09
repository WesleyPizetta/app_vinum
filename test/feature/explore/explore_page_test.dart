import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vinum/feature/explore/domain/entity/learn_topic.dart';
import 'package:vinum/feature/explore/presentation/page/explore_page.dart';
import 'package:vinum/feature/explore/presentation/widget/learn_topic_sheet.dart';

// Sem AppLocalization no teste, `getString` devolve a própria chave.
void main() {
  testWidgets('mostra o cabeçalho, a dica do dia e abre o tópico',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ExplorePage())),
    );

    expect(find.text('explore_learn_title'), findsOneWidget);
    expect(find.text('explore_daily_tip_title'), findsOneWidget);
    expect(find.text('learn_body_title'), findsOneWidget);

    await tester.tap(find.text('learn_body_title'));
    await tester.pumpAndSettle();

    expect(find.text('learn_body_intro'), findsOneWidget);
    expect(find.text('learn_body_point_1'), findsOneWidget);

    final closeButton = find.text('learn_sheet_close');
    await tester.scrollUntilVisible(
      closeButton,
      200,
      scrollable: find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(closeButton);
    await tester.pumpAndSettle();
    expect(find.text('learn_body_intro'), findsNothing);
  });

  testWidgets('showLearnTopicSheet abre o conteúdo do tópico',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showLearnTopicSheet(context, LearnTopic.tannins),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('learn_tannins_title'), findsOneWidget);
    expect(find.text('learn_tannins_intro'), findsOneWidget);
  });
}
