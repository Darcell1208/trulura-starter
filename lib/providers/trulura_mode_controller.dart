import 'package:flutter/material.dart';

/// High-level UI “modes” that control the global palette (background + glow).
///
/// This intentionally lives outside [AppProvider] so the visual system can be
/// evolved independently of product logic.
enum TruLuraMode { social, aura, sync, vent, trending }

@immutable
class TruLuraPalette {
  final Color bg0;
  final Color bg1;
  final Color glowA;
  final Color glowB;
  final Color card;
  final Color border;
  final Color text;
  final Color muted;

  const TruLuraPalette({required this.bg0, required this.bg1, required this.glowA, required this.glowB, required this.card, required this.border, required this.text, required this.muted});
}

const Map<TruLuraMode, TruLuraPalette> kTruLuraPalettes = {
  TruLuraMode.social: TruLuraPalette(
    bg0: Color(0xFF090A14),
    bg1: Color(0xFF141A3A),
    glowA: Color(0xFF7C4DFF),
    glowB: Color(0xFF00E5FF),
    card: Color(0x331B255A),
    border: Color(0x33FFFFFF),
    text: Color(0xFFF2F4FF),
    muted: Color(0xB3B9C2FF),
  ),
  TruLuraMode.aura: TruLuraPalette(
    bg0: Color(0xFF070812),
    bg1: Color(0xFF1A1040),
    glowA: Color(0xFFB388FF),
    glowB: Color(0xFFFF5ACD),
    card: Color(0x331A1555),
    border: Color(0x33FFFFFF),
    text: Color(0xFFF4F1FF),
    muted: Color(0xB3C8B9FF),
  ),
  TruLuraMode.sync: TruLuraPalette(
    bg0: Color(0xFF060716),
    bg1: Color(0xFF22124A),
    glowA: Color(0xFF8E7CFF),
    glowB: Color(0xFFFF4FD8),
    card: Color(0x331B1A5A),
    border: Color(0x33FFFFFF),
    text: Color(0xFFF2F4FF),
    muted: Color(0xB3B9C2FF),
  ),
  TruLuraMode.vent: TruLuraPalette(
    bg0: Color(0xFF05060F),
    bg1: Color(0xFF0F1B3A),
    glowA: Color(0xFF5AD6FF),
    glowB: Color(0xFF7C4DFF),
    card: Color(0x3311173D),
    border: Color(0x33FFFFFF),
    text: Color(0xFFF2F7FF),
    muted: Color(0xB3B7C9FF),
  ),
  TruLuraMode.trending: TruLuraPalette(
    bg0: Color(0xFF060610),
    bg1: Color(0xFF2A0F38),
    glowA: Color(0xFFFFD54F),
    glowB: Color(0xFFFF5ACD),
    card: Color(0x33200F3A),
    border: Color(0x33FFFFFF),
    text: Color(0xFFFFFBF2),
    muted: Color(0xB3FFE7C2),
  ),
};

class TruLuraModeController extends ChangeNotifier {
  TruLuraMode _mode;
  TruLuraModeController(this._mode);

  TruLuraMode get mode => _mode;
  TruLuraPalette get palette => kTruLuraPalettes[_mode]!;

  void setMode(TruLuraMode value) {
    if (_mode == value) return;
    _mode = value;
    notifyListeners();
  }
}
