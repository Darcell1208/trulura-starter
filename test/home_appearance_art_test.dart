import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/widgets/home_companion_rail.dart';

void main() {
  testWidgets('quiet appearances omit artwork but preserve feature actions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppProvider();
    await tester.pumpWidget(MultiProvider(providers: [ChangeNotifierProvider<AppProvider>.value(
      value: app)], child: DefaultAssetBundle(bundle: _ArtworkBundle(), child: const MaterialApp(home: Scaffold(body: HomeCompanionRail())))));
    expect(find.byType(Image), findsWidgets);
    for (final mode in ['neutral', 'light', 'dark']) {
      await app.setAppearanceMode(mode);
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      expect(find.text('Open companion'), findsOneWidget);
      expect(find.text('Explore worlds'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await app.setAppearanceMode('trulura');
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });
}

class _ArtworkBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(<String, dynamic>{})!;
    }
    return ByteData.sublistView(await File(key).readAsBytes());
  }
}