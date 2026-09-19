import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trulura/widgets/compact_feed_card_presentation.dart';
import 'package:trulura/widgets/feed_card_presentation.dart';

void main() {
  testWidgets('compact preview opens scrollable full text and closes',
      (tester) async {
    final text =
        '${List.filled(100, 'A longer reflection.').join(' ')} THE END';
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
      builder: (context) => const CompactFeedCardPresentation().build(
        context,
        FeedCardPresentationData(
          name: null,
          vibe: null,
          text: text,
          auraColor: Colors.blue,
          avatar: null,
          onProfile: null,
          onMore: () {},
          actions: const [],
        ),
      ),
    ))));
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('compact-preview')))
            .maxLines,
        2);
    await tester.tap(find.byKey(const ValueKey('compact-preview')));
    await tester.pumpAndSettle();
    expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data, text);
    expect(tester.widget<SelectableText>(find.byType(SelectableText)).maxLines,
        isNull);
    expect(tester.widget<AlertDialog>(find.byType(AlertDialog)).scrollable,
        isTrue);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byKey(const ValueKey('compact-preview')), findsOneWidget);
  });
}
