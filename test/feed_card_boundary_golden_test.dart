import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/models/feed_item.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/models/experience/experience_mode.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/experience_mode_controller.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_feed_item_renderer.dart';
import 'package:trulura/widgets/feed_card.dart';
import 'package:trulura/widgets/feed_card_visual_spec.dart';
import 'package:trulura/widgets/trulura_icon.dart';

// Captured against the pre-boundary working tree. Never update these to make
// the boundary refactor pass. Flutter's local comparator requires exact pixels.
// Fixed viewport/DPR, fixture identity, no network images/backend, and explicit
// pump durations keep the animation frames repeatable. The future timestamp
// deliberately exercises the stable 'just now' branch without a wall clock.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    final fonts = <String, Uint8List>{};
    for (final family in ['SpaceGrotesk', 'Inter']) {
      final bytes = File('test/fixtures/fonts/$family.ttf').readAsBytesSync();
      for (final weight in [
        'Regular',
        'Medium',
        'SemiBold',
        'Bold',
        'ExtraBold',
        'Black'
      ]) {
        fonts['test_fonts/$family-$weight.ttf'] = bytes;
      }
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message);
      if (key == 'AssetManifest.bin') {
        return const StandardMessageCodec().encodeMessage({
          for (final path in fonts.keys)
            path: [
              {'asset': path}
            ],
        });
      }
      final bytes = fonts[key];
      return bytes == null ? null : ByteData.sublistView(bytes);
    });
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('accent injection paints the border without changing text',
      (tester) async {
    tester.view.physicalSize = const Size(640, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = AppProvider();
    final date = DateTime.utc(2099);
    final post = Post(
        id: 'color-positive',
        userId: 'author',
        user: User.fromJson({'id': 'author', 'name': 'River'}),
        content: 'A small moment worth sharing.',
        type: 'text',
        moodTag: 'reflective',
        privacy: 'public',
        category: 'Social',
        createdAt: date,
        updatedAt: date);
    final original = FeedCardVisualSpec.fromPost(post, TruLuraMode.aura);
    // Only accentB changes. Text, geometry, seed, and motion are identical.
    final green = FeedCardVisualSpec(
        label: original.label,
        glyph: original.glyph,
        accentA: original.accentA,
        accentB: const Color(0xFF00FF00),
        radius: original.radius,
        leftInset: original.leftInset,
        topLift: original.topLift,
        bottomBreath: original.bottomBreath,
        seed: original.seed,
        emotionalWeight: original.emotionalWeight,
        motionTempo: original.motionTempo,
        floatRange: original.floatRange,
        compression: original.compression,
        gravity: original.gravity);
    Widget render(FeedCardVisualSpec? spec) => MultiProvider(
            providers: [
              ChangeNotifierProvider<AppProvider>(create: (_) => app),
              ChangeNotifierProvider<TruLuraModeController>(
                  create: (_) => TruLuraModeController(TruLuraMode.aura)),
              ChangeNotifierProvider<ExperienceModeController>(
                  create: (_) => ExperienceModeController(appProvider: app)),
            ],
            child: MaterialApp(
                theme: darkTheme,
                home: Scaffold(
                    body: SingleChildScrollView(
                        child: RepaintBoundary(
                            key: const ValueKey('positive-capture'),
                            child: TruluraFeedItemRenderer(
                                item: TruPostFeedItem(post: post),
                                visualSpec: spec))))));
    final capture = find.byKey(const ValueKey('positive-capture'));
    Future<ui.Image> pixels() async => (await tester.runAsync(() => tester
        .renderObject<RenderRepaintBoundary>(capture)
        .toImage(pixelRatio: 1)))!;
    // Paint the actual laid-out paragraph on transparency, excluding the aura
    // behind it. Composited text rectangles legitimately change with the aura.
    Future<Uint8List> textPixels(Finder finder) async =>
        (await tester.runAsync(() async {
          final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(of: finder, matching: find.byType(RichText)));
          final layer = OffsetLayer();
          final bounds = Offset.zero & paragraph.size;
          final context = _ParagraphPaintingContext(layer, bounds);
          paragraph.paint(context, Offset.zero);
          context.finish();
          final image = await layer.toImage(bounds, pixelRatio: 1);
          final bytes =
              (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
                  .buffer
                  .asUint8List();
          image.dispose();
          layer.dispose();
          return bytes;
        }))!;

    await tester.pumpWidget(render(null));
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.pump();
    final textFinders = [find.text('River'), find.text(post.content)];
    final rects = [for (final f in textFinders) tester.getRect(f)];
    final foregrounds = [for (final f in textFinders) await textPixels(f)];
    final before = await pixels();
    final beforeBytes = (await tester.runAsync(
            () => before.toByteData(format: ui.ImageByteFormat.rawRgba)))!
        .buffer
        .asUint8List();
    final cardRect = tester
        .getRect(find
            .descendant(
                of: find.byType(FeedCard), matching: find.byType(ClipRRect))
            .first)
        .shift(-tester.getTopLeft(capture));
    await tester.pumpWidget(
        render(green)); // No elapsed time: identical animation phase.
    final after = await pixels();
    final afterBytes = (await tester.runAsync(
            () => after.toByteData(format: ui.ImageByteFormat.rawRgba)))!
        .buffer
        .asUint8List();
    expect(after.width, before.width);
    expect(after.height, before.height);
    // Straight top border only, excluding rounded corners and all text.
    final y = cardRect.top.ceil();
    final left = (cardRect.left + original.radius + 20).ceil();
    final right = (cardRect.right - original.radius - 20).floor();
    var changed = 0;
    var total = 0;
    var greenShift = 0;
    for (var x = left; x < right; x++) {
      final i = (y * before.width + x) * 4;
      final delta = (afterBytes[i] - beforeBytes[i]).abs() +
          (afterBytes[i + 1] - beforeBytes[i + 1]).abs() +
          (afterBytes[i + 2] - beforeBytes[i + 2]).abs();
      if (delta >= 30) changed++;
      greenShift += (afterBytes[i + 1] - afterBytes[i + 2]) -
          (beforeBytes[i + 1] - beforeBytes[i + 2]);
      total++;
    }
    expect(total, greaterThan(400));
    expect(changed / total, greaterThan(0.90),
        reason: 'At least 90% of the straight border must change materially');
    expect(greenShift / total, greaterThan(20),
        reason: 'Border must shift toward green, not merely differ');
    for (var i = 0; i < textFinders.length; i++) {
      expect(tester.getRect(textFinders[i]), rects[i]);
      expect(await textPixels(textFinders[i]), orderedEquals(foregrounds[i]));
    }
    await expectLater(capture,
        matchesGoldenFile('goldens/feed_boundary/positive_accent_green.png'));
    await tester.pumpWidget(render(null));
    final restored = await pixels();
    expect(
        (await tester.runAsync(
                () => restored.toByteData(format: ui.ImageByteFormat.rawRgba)))!
            .buffer
            .asUint8List(),
        orderedEquals(beforeBytes));
    before.dispose();
    after.dispose();
    restored.dispose();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final surface in ['vent', 'profile', 'profile_boosted']) {
    for (final width in [300.0, 640.0]) {
      for (final light in [false, true]) {
        for (final explicitDefault in [false, true]) {
          testWidgets(
              '$surface $width light=$light explicit=$explicitDefault unchanged',
              (tester) async {
            tester.view.physicalSize = Size(width, 1500);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final vent = surface == 'vent';
            final app = AppProvider();
            final experience = ExperienceModeController(appProvider: app);
            if (vent) {
              await experience.setActiveMode(TruExperienceMode.vent,
                  confirmed: true);
            }
            final date = DateTime.utc(2099);
            final post = Post(
              id: 'boundary-$surface',
              userId: 'fixture-author',
              user: User.fromJson({
                'id': 'fixture-author',
                'name': 'River',
                'username': 'river'
              }),
              content:
                  'A small moment worth sharing. Finding room to breathe today.',
              type: surface == 'profile_boosted' ? 'video' : 'text',
              moodTag: vent ? 'calm' : 'reflective',
              privacy: vent ? 'private' : 'public',
              category: vent ? 'Vent' : 'Social',
              isAnonymous: vent,
              isBoosted: surface == 'profile_boosted',
              createdAt: date,
              updatedAt: date,
            );
            Widget render({FeedCardVisualSpec? spec}) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider<AppProvider>(create: (_) => app),
                    ChangeNotifierProvider<TruLuraModeController>(
                        create: (_) => TruLuraModeController(
                            vent ? TruLuraMode.vent : TruLuraMode.aura)),
                    ChangeNotifierProvider<ExperienceModeController>(
                        create: (_) => experience),
                  ],
                  child: MaterialApp(
                      theme: light ? lightTheme : darkTheme,
                      home: Scaffold(
                          body: SingleChildScrollView(
                              child: RepaintBoundary(
                        key: const ValueKey('capture'),
                        child: TruluraFeedItemRenderer(
                            visualSpec: spec,
                            item: TruPostFeedItem(
                              post: post,
                              boosted: surface == 'profile_boosted',
                              why: 'Fixture',
                            )),
                      )))),
                );
            await tester.pumpWidget(render(
                spec: explicitDefault
                    ? FeedCardVisualSpec.fromPost(
                        post, vent ? TruLuraMode.vent : TruLuraMode.aura)
                    : null));
            await tester.runAsync(() => GoogleFonts.pendingFonts());
            await tester.pump();
            for (final frame in [0, 300]) {
              if (frame != 0) await tester.pump(Duration(milliseconds: frame));
              expect(tester.takeException(), isNull);
              await expectLater(
                  find.byKey(const ValueKey('capture')),
                  matchesGoldenFile(
                      'goldens/feed_boundary/${surface}_${width.toInt()}_${light ? 'light' : 'dark'}_$frame.png'));
            }
            // Prove injection passes through both normal and boosted renderers,
            // is consumed by the card body, and can be removed on the same state.
            const injected = FeedCardVisualSpec(
              label: 'Injected appearance',
              glyph: TruLuraGlyph.spark,
              accentA: Colors.green,
              accentB: Colors.orange,
              radius: 17,
              leftInset: 0,
              topLift: 0,
              bottomBreath: 0,
              seed: 42,
              emotionalWeight: 0.5,
              motionTempo: 0,
              floatRange: 0,
              compression: 1,
            );
            await tester.pumpWidget(render(spec: injected));
            expect(tester.widget<FeedCard>(find.byType(FeedCard)).visualSpec,
                same(injected));
            expect(find.text('Injected appearance'), findsOneWidget);
            await tester.pumpWidget(render());
            expect(tester.widget<FeedCard>(find.byType(FeedCard)).visualSpec,
                isNull);
            expect(find.text('Injected appearance'), findsNothing);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          });
        }
      }
    }
  }
}

// Expose completion of the isolated foreground recording through a subclass;
// PaintingContext's recording lifecycle is protected.
class _ParagraphPaintingContext extends PaintingContext {
  _ParagraphPaintingContext(super.containerLayer, super.estimatedBounds);
  void finish() => stopRecordingIfNeeded();
}
