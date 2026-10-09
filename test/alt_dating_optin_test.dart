import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/experience/experience_mode.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/app_settings_service.dart';
import 'package:trulura/providers/experience_mode_controller.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Alt requires dating opt-in and is disabled with its parent', () async {
    SharedPreferences.setMockInitialValues({});
    final app = AppProvider();
    app.setCurrentUser(User.fromJson({'id':'adult','age':25}).copyWith(verificationLevel:TruVerificationLevel.level3));
    final controller = ExperienceModeController(appProvider:app);
    await controller.initialize();
    expect(await controller.setActiveMode(TruExperienceMode.altIntimate,confirmed:true),isFalse);
    await controller.setEnabled(TruExperienceMode.dating,true);
    expect(await controller.setActiveMode(TruExperienceMode.altIntimate,confirmed:true),isTrue);
    await controller.setEnabled(TruExperienceMode.dating,false);
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