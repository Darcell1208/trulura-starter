import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trulura/widgets/compact_feed_card_presentation.dart';
import 'package:trulura/widgets/feed_card_presentation.dart';

void main() {
  testWidgets('attached image has a media area and a recoverable load failure',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: Builder(
      builder: (context) => const CompactFeedCardPresentation().build(
          context,
          FeedCardPresentationData(
              name: 'Test',
              vibe: null,
              text: 'Caption',
              imageUrl: 'missing-test-image.png',
              auraColor: Colors.blue,
              avatar: null,
              onProfile: null,
              onMore: () {},
              actions: const [])),
    )))));
    await tester.pumpAndSettle();
    expect(find.text('Image unavailable'), findsOneWidget);
    expect(find.text('Caption'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('existing photo decodes in compact feed without hiding caption',
      (tester) async {
    const path =
        'assets/images/sunset_landscape_beautiful_null_1772162279309.jpg';
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: Builder(
      builder: (context) => const CompactFeedCardPresentation().build(
          context,
          FeedCardPresentationData(
              name: 'Fixture',
              vibe: null,
              text: 'Photo caption',
              imageUrl: path,
              auraColor: Colors.blue,
              avatar: null,
              onProfile: null,
              onMore: () {},
              actions: const [])),
    )))));
    await tester.runAsync(() async {
      final context = tester.element(find.byType(Image));
      await precacheImage(const AssetImage(path), context);
    });
    await tester.pumpAndSettle();
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    expect(find.text('Photo caption'), findsOneWidget);
    expect(find.text('Image unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
