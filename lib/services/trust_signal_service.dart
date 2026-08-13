import 'package:flutter/material.dart';
import 'package:trulura/models/user.dart';

/// Derives non-stigmatizing trust signals from the user's chosen indicators.
class TrustSignalService {
  const TrustSignalService();

  TruTrustSignal compute(User? user) {
    if (user == null) return const TruTrustSignal.none();

    final show = user.showTrustIndicator;
    if (!show) return const TruTrustSignal.none();

    // Keep it subtle: avoid numeric "risk" labeling.
    final score = user.trustScore.clamp(0, 100);
    final v = user.verificationLevel;

    if (v.index >= TruVerificationLevel.level3.index && score >= 80) {
      return TruTrustSignal(label: 'Highly Trusted', tone: TruTrustTone.positive);
    }
    if (v.index >= TruVerificationLevel.level2.index && score >= 65) {
      return TruTrustSignal(label: 'Safe to Meet', tone: TruTrustTone.positive);
    }
    if (v.index >= TruVerificationLevel.level2.index) {
      return TruTrustSignal(label: 'Verified', tone: TruTrustTone.positive);
    }
    if (v.index >= TruVerificationLevel.level1.index || score >= 55) {
      return TruTrustSignal(label: 'Trusted', tone: TruTrustTone.neutral);
    }
    return const TruTrustSignal(label: 'Standard', tone: TruTrustTone.neutral);
  }
}

enum TruTrustTone { positive, neutral, caution }

@immutable
class TruTrustSignal {
  final String? label;
  final TruTrustTone tone;

  const TruTrustSignal({required this.label, required this.tone});
  const TruTrustSignal.none() : label = null, tone = TruTrustTone.neutral;

  bool get isVisible => label != null && label!.trim().isNotEmpty;
}
