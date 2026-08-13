import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/openai/openai_config.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/experience_mode_controller.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';

class TruluraAiSuggestionsSheet {
  static Future<void> show({required BuildContext context, required String postText, required String feedTabLabel}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiSuggestionsBody(postText: postText, feedTabLabel: feedTabLabel),
    );
  }
}

class _AiSuggestionsBody extends StatefulWidget {
  final String postText;
  final String feedTabLabel;

  const _AiSuggestionsBody({required this.postText, required this.feedTabLabel});

  @override
  State<_AiSuggestionsBody> createState() => _AiSuggestionsBodyState();
}

class _AiSuggestionsBodyState extends State<_AiSuggestionsBody> {
  bool _loading = true;
  Object? _error;
  List<String> _suggestions = const <String>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app = context.read<AppProvider>();
    final mode = context.read<ExperienceModeController>().participationContext.activeMode;
    final mood = (app.currentUser?.moodTags.isNotEmpty ?? false) ? app.currentUser!.moodTags.first : 'neutral';

    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final fallback = _localFallback(mood: mood, mode: mode.name, tab: widget.feedTabLabel);
      if (!TruOpenAI.isConfigured) {
        setState(() {
          _suggestions = fallback;
        });
        return;
      }

      final ai = TruOpenAI();
      final res = await ai.suggestReplies(postText: widget.postText, mood: mood, mode: mode.name, feedTab: widget.feedTabLabel);
      setState(() {
        _suggestions = res;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _suggestions = _localFallback(mood: mood, mode: mode.name, tab: widget.feedTabLabel);
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<String> _localFallback({required String mood, required String mode, required String tab}) {
    final m = mood.toLowerCase();
    if (tab.toLowerCase().contains('vent')) {
      return const [
        'I hear you. Do you want advice or just presence?',
        'That sounds heavy. I’m here with you.',
        'Thank you for sharing. What would help right now?',
        'No pressure to explain more. You’re not alone.',
      ];
    }
    if (tab.toLowerCase().contains('spark') || mode.toLowerCase().contains('dating')) {
      return const [
        'This is such a vibe. What inspired it?',
        'I’m curious—what are you into lately?',
        'Your energy feels aligned. Want to connect?',
        'What’s one thing you’re excited about this week?',
      ];
    }
    if (m.contains('low') || m.contains('tired') || m.contains('anx')) {
      return const [
        'Soft check-in: how are you really doing today?',
        'This resonated. Want a gentle conversation?',
        'Appreciate you sharing this. Sending calm.',
        'What’s one small thing that helped recently?',
      ];
    }
    return const [
      'Love this. Tell me more about it.',
      'This hit. What’s the story behind it?',
      'Your vibe is bright today—what’s fueling it?',
      'I’m into this perspective. Want to connect?',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: TruLuraGlassCard(
          radius: 26,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          depth: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const TruLuraIcon(glyph: TruLuraGlyph.spark, size: 20, active: true),
                  const SizedBox(width: 10),
                  Expanded(child: Text('AI assist', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                  IconButton(onPressed: () => context.pop(), icon: TruLuraIcon(glyph: TruLuraGlyph.close, size: 18, active: false, color: cs.onSurface.withValues(alpha: 0.8))),
                ],
              ),
              const SizedBox(height: 8),
              Text('Mood-aware reply suggestions (optional).', style: t.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.3)),
              const SizedBox(height: 12),
              if (_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [const SizedBox(width: 2), const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 12), Text('Generating…', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800))]),
                )
              else ...[
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('Using local suggestions (AI unavailable).', style: t.labelMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800)),
                  ),
                ..._suggestions.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied suggestion (stub).')));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.40),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: TruLuraSurfaces.hairline),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(s, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
                              const SizedBox(width: 10),
                              TruLuraIcon(glyph: TruLuraGlyph.chevronRight, size: 16, active: false, color: cs.onSurface.withValues(alpha: 0.7)),
                            ],
                          ),
                        ),
                      ),
                    )),
              ],
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : _load,
                  child: Text('Regenerate', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
