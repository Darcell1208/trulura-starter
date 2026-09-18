import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/models/feed_item.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/aura_state.dart';
import 'package:trulura/providers/experience_mode_controller.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/theme/mood_palette.dart';
import 'package:trulura/widgets/compact_feed_card_presentation.dart';
import 'package:trulura/widgets/feed_card_visual_spec.dart';
import 'package:trulura/widgets/trulura_feed_item_renderer.dart';

/// Mood harness: one compact card per Mood, stacked adjacent, plus an untagged
/// post, so the mood chips can be compared side by side.
///
/// Each card is built the way the Aura feed builds it (home_feed_screen.dart,
/// the _FeedPostItem branch): FeedCardVisualSpec.fromPost with the ring
/// injected as accentB -- the aura tone, not a mood colour. Ring is aura, chip
/// is mood; the golden changes when either the palette or that split does.
///
/// Asserts four things: the ring is the same colour on every card whatever the
/// mood, each chip dot is painted from MoodPalette (the DR-2 source FeedCard
/// now uses), the five dot colours are all different from each other, and an
/// untagged post gets no dot.
///
/// The distinctness check is the point of this harness. Before 2026-09-17 the
/// dot came from MoodColors.glow, which keys on a different vocabulary, so
/// Reflective, Flirty, Social and Healing all fell through to one default
/// purple and only Calm was itself. Four moods sharing a colour is invisible in
/// a golden nobody reviews; it is loud in an assertion. Build Status known
/// issue 25.
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
    expect(darkTheme.textTheme.bodyMedium, isNotNull);
    await GoogleFonts.pendingFonts();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('compact card per mood, as the Aura feed builds it',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1140);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Five Mood values, then a post with no mood tag at all.
    final moodTags = <String?>[
      for (final m in Mood.values) m.name[0].toUpperCase() + m.name.substring(1),
      null,
    ];
    const photos = [
      'assets/images/portrait_young_woman_smiling_null_1772162274859.jpg',
      'assets/images/portrait_man_glasses_null_1772162276625.jpg',
      'assets/images/portrait_woman_outdoor_null_1772162277798.jpg',
    ];
    const text =
        'A quiet morning, a good playlist, and nowhere to rush. Some days ask for less.';
    final app = AppProvider();
    final now = DateTime.utc(2099);
    final ringColor = TruLuraModeTone.aura.resolve(darkTheme.colorScheme).$1;

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
                    key: const ValueKey('mood-harness'),
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < moodTags.length; i++) ...[
                                Builder(builder: (context) {
                                  final name = moodTags[i] ?? 'Untagged';
                                  final post = Post(
                                      id: 'mood-harness-$i',
                                      userId: name,
                                      user: User.fromJson({
                                        'id': name,
                                        'name': name,
                                        'profileImage': photos[i % photos.length]
                                      }),
                                      content: text,
                                      type: 'text',
                                      privacy: 'public',
                                      category: 'Social',
                                      moodTag: moodTags[i],
                                      likeCount: 12,
                                      commentCount: 3,
                                      shareCount: 1,
                                      createdAt: now,
                                      updatedAt: now);
                                  return TruluraFeedItemRenderer(
                                      item: TruPostFeedItem(post: post),
                                      visualSpec: FeedCardVisualSpec.fromPost(
                                              post, TruLuraMode.aura)
                                          .withPresentation(
                                              const CompactFeedCardPresentation(),
                                              accentB: TruLuraModeTone.aura
                                                  .resolve(Theme.of(context)
                                                      .colorScheme)
                                                  .$1));
                                }),
                                const SizedBox(height: 8),
                              ],
                            ])))))));
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('compact-feed-card')),
        findsNWidgets(moodTags.length));
    final tagged = moodTags.whereType<String>().toList();
    // The untagged post has no mood, so it gets no chip at all rather than an
    // empty pill: one chip per tagged post, one fewer than there are cards.
    expect(find.byKey(const ValueKey('compact-mood-chip')),
        findsNWidgets(tagged.length));
    final dots = find.byKey(const ValueKey('compact-mood-chip-dot'));
    expect(dots, findsNWidgets(tagged.length),
        reason: 'An untagged post gets no dot, not a guessed colour');

    final capture = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('mood-harness')));
    final image = (await tester.runAsync(() => capture.toImage(pixelRatio: 1)))!;
    final bytes = (await tester.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!
        .buffer
        .asUint8List();
    final origin = tester.getTopLeft(find.byKey(const ValueKey('mood-harness')));
    List<int> rgbAt(Offset p) {
      final i = (p.dy.floor() * image.width + p.dx.floor()) * 4;
      return bytes.sublist(i, i + 3);
    }

    List<int> channels(Color c) =>
        [(c.r * 255).round(), (c.g * 255).round(), (c.b * 255).round()];

    for (var i = 0; i < moodTags.length; i++) {
      final rect = tester
          .getRect(find.byKey(const ValueKey('compact-mood-ring')).at(i))
          .shift(-origin);
      // Center-left, one pixel inside the 2px ring, outside the photo.
      expect(rgbAt(Offset(rect.left + 1, rect.center.dy)), channels(ringColor),
          reason: 'Ring for ${moodTags[i] ?? 'untagged'} must be the aura '
              'tone, the same on every card: the ring does not carry mood');
    }

    final painted = <String>[];
    for (var i = 0; i < tagged.length; i++) {
      final rgb = rgbAt(tester.getCenter(dots.at(i)) - origin);
      final expected = MoodPalette.dotFor(tagged[i]);
      expect(expected, isNotNull,
          reason: '${tagged[i]} must parse to a Mood; an unparsed tag draws no '
              'dot at all rather than a guessed colour');
      expect(rgb, channels(expected!),
          reason: 'Chip dot for ${tagged[i]} must be painted from '
              'MoodPalette.stop1, the DR-2 source FeedCard uses');
      painted.add('${tagged[i]}='
          '#${rgb.map((c) => c.toRadixString(16).padLeft(2, '0')).join().toUpperCase()}');
    }

    // Five moods must paint five colours. Issue 25 was four of them painting
    // one purple, because a Mood was matched against a foreign vocabulary and
    // fell through to a default. A distinctness check is what catches that
    // class; comparing each dot only against its own expected value would not,
    // since the expectation would collapse along with the implementation.
    expect(painted.map((p) => p.split('=').last).toSet(), hasLength(tagged.length),
        reason: 'Each mood needs its own DR-2 colour, got: $painted');
    image.dispose();
    // ignore: avoid_print
    print('mood harness chip dots: ${painted.join(', ')}');

    // NOT EVIDENCE. This golden was regenerated with --update-goldens after
    // failing, and records what the widget draws, not what it should.
    // Read test/goldens/compact_feed/README.md before trusting a pass.
    await expectLater(find.byKey(const ValueKey('mood-harness')),
        matchesGoldenFile('goldens/compact_feed/moods.png'));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
