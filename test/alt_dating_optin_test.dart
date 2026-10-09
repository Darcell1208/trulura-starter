import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/experience/experience_mode.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/app_settings_service.dart';
import 'package:trulura/services/experience_mode_service.dart';
import 'package:trulura/providers/experience_mode_controller.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('legacy Alt state without Dating is cleared and persisted on startup', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ExperienceModeService();
    final saved = await service.getModes(userId:'adult');
    saved[TruExperienceMode.dating] = saved[TruExperienceMode.dating]!.copyWith(isEnabled:false);
    saved[TruExperienceMode.altIntimate] = saved[TruExperienceMode.altIntimate]!.copyWith(isEnabled:true);
    await service.setModes(saved,userId:'adult');
    await service.setActiveMode(TruExperienceMode.altIntimate,userId:'adult');
    final app = AppProvider();
    app.setCurrentUser(User.fromJson({'id':'adult','age':25}).copyWith(verificationLevel:TruVerificationLevel.level3));
    final controller = ExperienceModeController(appProvider:app,service:service);
    await controller.initialize();
    expect(controller.activeMode,TruExperienceMode.social);
    expect(controller.enabledModes,isNot(contains(TruExperienceMode.altIntimate)));
    expect((await service.getModes(userId:'adult'))[TruExperienceMode.altIntimate]!.isEnabled,isFalse);
    expect(await service.getActiveMode(userId:'adult'),TruExperienceMode.social);
    controller.dispose(); app.dispose();
  });
  test('Alt requires dating opt-in and is disabled with its parent', () async {
    SharedPreferences.setMockInitialValues({});
    final app = AppProvider();
    app.setCurrentUser(User.fromJson({'id':'adult','age':25}).copyWith(verificationLevel:TruVerificationLevel.level3));
    final controller = ExperienceModeController(appProvider:app);
    await controller.initialize();
    expect(await controller.setActiveMode(TruExperienceMode.altIntimate,confirmed:true),isFalse);
    void expectAltBlocked() {
      final permissions = controller.permissionsFor(TruExperienceMode.altIntimate);
      expect([
        permissions.messaging, permissions.matching, permissions.monetization,
        permissions.anonymousUse, permissions.groups, permissions.live,
        permissions.events,
      ], everyElement(TruPermissionLevel.blocked));
      expect(permissions.allowRomanticEscalation, isFalse);
    }
    expectAltBlocked();
    await controller.setEnabled(TruExperienceMode.dating,true);
    expect(await controller.setActiveMode(TruExperienceMode.altIntimate,confirmed:true),isTrue);
    expect(controller.permissionsFor(TruExperienceMode.altIntimate).matching, isNot(TruPermissionLevel.blocked));
    await controller.setEnabled(TruExperienceMode.dating,false);
    expectAltBlocked();
    expect(controller.stateOf(TruExperienceMode.altIntimate).isEnabled,isFalse);
    expect(controller.activeMode,TruExperienceMode.social);
    expect(app.useMode, 'social');
    expect(await AppSettingsService().getUseMode(userId:'adult'), 'social');
    expect(controller.passiveModes, isNot(contains(TruExperienceMode.altIntimate)));
    final restored = ExperienceModeController(appProvider:app);
    await restored.initialize();
    expect(restored.stateOf(TruExperienceMode.altIntimate).isEnabled,isFalse);
    expect(restored.activeMode,TruExperienceMode.social);
    restored.dispose(); controller.dispose(); app.dispose();
  });
}