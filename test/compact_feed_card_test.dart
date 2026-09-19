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
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/experience_mode_controller.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_feed_item_renderer.dart';
import 'package:trulura/widgets/compact_feed_card_presentation.dart';
import 'package:trulura/widgets/feed_card_presentation.dart';
import 'package:trulura/widgets/feed_card_visual_spec.dart';

// Compact fixtures; original baseline tests stay in their own suite.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(
          File('test/fixtures/fonts/materialicons-regular.otf')
              .readAsBytesSync())));
    await icons.load();
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
      if (key != null && key.startsWith('assets/images/')) {
        return ByteData.sublistView(File(key).readAsBytesSync());
      }
      final bytes = fonts[key];
      return bytes == null ? null : ByteData.sublistView(bytes);
    });
    // Load theme fonts before the first layout, not while the ring fixture is
    // on screen; both comparison options must start with identical metrics.
    expect(darkTheme.textTheme.bodyMedium, isNotNull);
    await GoogleFonts.pendingFonts();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final indicator in FeedMoodIndicator.values) {
    testWidgets('compact preview ${indicator.name}', (tester) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final app = AppProvider();
      final now = DateTime.utc(2099);
      final colors = [
        const Color(0xFF6AD4F5),
        const Color(0xFFCDA0FA),
        const Color(0xFFF0B979)
      ];
      final names = ['Nova', 'Max', 'Aria'];
      final moods = ['Calm', 'Reflective', 'Energetic'];
      final texts = [
        'You have such a peaceful presence. Some people make a whole day feel softer.',
        'A quiet morning, a good playlist, and nowhere to rush.',
        'Took the long way home today. Sometimes a little detour is exactly what you need.'
      ];
      final photos = [
        'assets/images/portrait_young_woman_smiling_null_1772162274859.jpg',
        'assets/images/portrait_man_glasses_null_1772162276625.jpg',
        'assets/images/portrait_woman_outdoor_null_1772162277798.jpg'
      ];
      await tester.pumpWidget(MultiProvider(
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
                  body: RepaintBoundary(
                      key: const ValueKey('preview'),
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    indicator == FeedMoodIndicator.ring
                                        ? '40px avatar / 2px mood ring'
                                        : '40px avatar / 7px mood dot',
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.white70)),
                                const SizedBox(height: 14),
                                for (var i = 0; i < 3; i++) ...[
                                  Builder(builder: (context) {
                                    final post = Post(
                                        id: 'compact-$i',
                                        userId: names[i],
                                        user: User.fromJson({
                                          'id': names[i],
                                          'name': names[i],
                                          'profileImage': photos[i]
                                        }),
                                        content: texts[i],
                                        type: 'text',
                                        privacy: 'public',
                                        category: 'Social',
                                        moodTag: moods[i],
                                        likeCount: 12 + i * 9,
                                        commentCount: 3 + i,
                                        createdAt: now,
                                        updatedAt: now);
                                    return TruluraFeedItemRenderer(
                                        item: TruPostFeedItem(post: post),
                                        visualSpec: FeedCardVisualSpec.fromPost(
                                                post, TruLuraMode.aura)
                                            .withPresentation(
                                                CompactFeedCardPresentation(
                                                    moodIndicator: indicator),
                                                accentB: colors[i]));
                                  }),
                                  const SizedBox(height: 10),
                                ],
                              ])))))));
      await tester.runAsync(() => GoogleFonts.pendingFonts());
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('compact-feed-card')), findsNWidgets(3));
      if (indicator == FeedMoodIndicator.ring) {
        final capture = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('preview')));
        final image =
            (await tester.runAsync(() => capture.toImage(pixelRatio: 1)))!;
        final bytes = (await tester.runAsync(
                () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
            .buffer
            .asUint8List();
        for (var i = 0; i < 3; i++) {
          final rect = tester
              .getRect(find.byKey(const ValueKey('compact-mood-ring')).at(i));
          // Sample center-left, one pixel inside the 2px ring, outside the photo.
          final pixel =
              (rect.center.dy.floor() * image.width + rect.left.floor() + 1) *
                  4;
          final color = colors[i];
          expect(
              bytes.sublist(pixel, pixel + 3),
              [
                (color.r * 255).round(),
                (color.g * 255).round(),
                (color.b * 255).round()
              ],
              reason:
                  'Injected ring color must paint independently of the shared Aura mode');
        }
        image.dispose();
      }
      // NOT EVIDENCE. This golden was regenerated with --update-goldens after
      // failing, and records what the widget draws, not what it should.
      // Read test/goldens/compact_feed/README.md before trusting a pass.
      await expectLater(find.byKey(const ValueKey('preview')),
          matchesGoldenFile('goldens/compact_feed/${indicator.name}.png'));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final config in [
    (240.0, 1.0, 1.0),
    (280.0, 2.0, 1.0),
    (320.0, 3.0, 1.0),
    (390.0, 1.0, 1.0),
    (430.0, 3.0, 1.0),
    (320.0, 2.0, 1.5)
  ]) {
    testWidgets('compact layout and callbacks $config', (tester) async {
      final (width, dpr, scale) = config;
      tester.view.physicalSize = Size(width * dpr, 400 * dpr);
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final calls = <String>[];
      Widget render(String text) => MaterialApp(
          theme: darkTheme,
          home: Scaffold(
              body: Builder(
                  builder: (context) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: TextScaler.linear(scale)),
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Builder(
                              builder: (inner) =>
                                  const CompactFeedCardPresentation().build(
                                      inner,
                                      FeedCardPresentationData(
                                          name:
                                              'Nova with a very long display name',
                                          vibe: 'Reflective and calm',
                                          text: text,
                                          auraColor: Colors.green,
                                          avatar: null,
                                          onProfile: () => calls.add('profile'),
                                          onMore: () => calls.add('more'),
                                          actions: [
                                            for (var i = 0; i < 4; i++)
                                              FeedCardAction(
                                                  icon: Icons.favorite_border,
                                                  label: 'action-$i',
                                                  count: 123456,
                                                  onTap: () =>
                                                      calls.add('action-$i')),
                                          ]))))))));
      await tester.pumpWidget(render('Short.'));
      await tester.runAsync(() => GoogleFonts.pendingFonts());
      await tester.pump();
      final height = tester
          .getSize(find.byKey(const ValueKey('compact-feed-card')))
          .height;
      await tester.pumpWidget(render(
          List.filled(30, 'A longer post that must truncate.').join(' ')));
      expect(
          tester
              .getSize(find.byKey(const ValueKey('compact-feed-card')))
              .height,
          height);
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('compact-preview')))
              .maxLines,
          2);
      final actionRects = [
        for (var i = 0; i < 4; i++) tester.getRect(find.byTooltip('action-$i'))
      ];
      expect(actionRects.map((r) => r.top).toSet().length, 1);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byTooltip('action-$i'));
      }
      await tester.tap(find.byTooltip('More'));
      await tester.tap(find.text('Nova with a very long display name'));
      expect(calls,
          ['action-0', 'action-1', 'action-2', 'action-3', 'more', 'profile']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
