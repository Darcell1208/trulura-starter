import 'package:flutter/foundation.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/aura_shield_service.dart';
import 'package:trulura/services/trust_signal_service.dart';

/// Safety Meter (9.18): controlled, subtle trust/risk visibility.
///
/// - Avoids numeric labels in UI
/// - Uses "confidence" framing + context
/// - Designed to expand only when the user opts in
class SafetyMeterService {
  const SafetyMeterService();

  TruSafetyMeter meterForUser(User? user) {
    if (user == null) return const TruSafetyMeter(level: TruSafetyMeterLevel.unknown, label: 'Unknown');
    final trust = const TrustSignalService().compute(user);

    if (user.verificationLevel.index >= TruVerificationLevel.level2.index) {
      return TruSafetyMeter(level: TruSafetyMeterLevel.strong, label: trust.isVisible ? trust.label! : 'Verified');
    }
    if (user.verificationLevel.index >= TruVerificationLevel.level1.index) {
      return TruSafetyMeter(level: TruSafetyMeterLevel.standard, label: trust.isVisible ? trust.label! : 'Standard');
    }
    return const TruSafetyMeter(level: TruSafetyMeterLevel.basic, label: 'Basic');
  }

  TruSafetyMeter meterForThread(AuraShieldAssessment assessment) {
    switch (assessment.level) {
      case AuraShieldLevel.low:
        return const TruSafetyMeter(level: TruSafetyMeterLevel.threadStable, label: 'Stable');
      case AuraShieldLevel.medium:
        return const TruSafetyMeter(level: TruSafetyMeterLevel.threadCaution, label: 'Caution');
      case AuraShieldLevel.high:
        return const TruSafetyMeter(level: TruSafetyMeterLevel.threadElevated, label: 'Elevated');
    }
  }
}

enum TruSafetyMeterLevel {
  unknown,
  basic,
  standard,
  strong,
  threadStable,
  threadCaution,
  threadElevated,
}

@immutable
class TruSafetyMeter {
  final TruSafetyMeterLevel level;
  final String label;

  const TruSafetyMeter({required this.level, required this.label});
}
