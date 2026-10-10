import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trulura/widgets/compact_feed_card_presentation.dart';
import 'package:trulura/widgets/feed_card_presentation.dart';

void main() {
  testWidgets('attached image has a media area and a recoverable load failure', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: Builder(
      builder: (context) => const CompactFeedCardPresentation().build(context,
        FeedCardPresentationData(name: 'Test', vibe: null, text: 'Caption',
          imageUrl: 'missing-test-image.png', auraColor: Colors.blue,
          avatar: null, onProfile: null, onMore: () {}, actions: const [])),
    )))));
    await tester.pumpAndSettle();
    expect(find.text('Image unavailable'), findsOneWidget);
    expect(find.text('Caption'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
