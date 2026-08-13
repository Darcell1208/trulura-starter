import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/models/profile/quiz_result.dart';
import 'package:trulura/models/quiz/quiz_registry_models.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/app_state.dart';
import 'package:trulura/services/compatibility_service.dart';
import 'package:trulura/services/quiz_engine.dart';
import 'package:trulura/services/quiz_registry_service.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_glow_pill.dart';

class MicroQuizScreen extends StatefulWidget {
  const MicroQuizScreen({super.key});

  @override
  State<MicroQuizScreen> createState() => _MicroQuizScreenState();
}

class _MicroQuizScreenState extends State<MicroQuizScreen> {
  static const TruQuizEngine _engine = TruQuizEngine();
  static const QuizRegistryService _registry = QuizRegistryService();
  static final CompatibilityService _compat = CompatibilityService();

  TruMicroQuizBlueprint? _quiz;
  TruQuizRegistryEntry? _entry;
  List<int?>? _answers;
  int _currentStep = 0;
  bool _isSaving = false;
  TruQuizVisibility? _selectedVisibility;
  TruQuizResult? _pendingResult;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_quiz != null && _answers != null) return;
    final quiz = _engine.microQuizById(_quizIdFromRoute());
    _quiz = quiz;
    _entry = _registry.byId(quiz.quizId);
    _selectedVisibility =
        _entry?.visibilityDefault ?? TruQuizVisibility.privateOnly;
    _answers = List<int?>.filled(quiz.questions.length, null);
  }

  String _quizIdFromRoute() {
    final routeQuizId = GoRouterState.of(context).uri.queryParameters['quiz'];
    if (routeQuizId != null && routeQuizId.trim().isNotEmpty) {
      return routeQuizId.trim();
    }
    return TruQuizEngine.friendshipEnergyMatchQuizId;
  }

  String _resolveReturnTo() {
    final extraReturnTo = TruNavigation.resolveReturnTo(context);
    if (extraReturnTo != null) return extraReturnTo;
    final route = GoRouterState.of(context).uri.queryParameters['returnTo'];
    if (route != null && route.trim().isNotEmpty) return route;
    return AppRoutes.homeTab('aura');
  }

  Future<void> _prepareResult() async {
    final userId = context.read<AppProvider>().currentUser?.id;
    final answers = _answers;
    final quiz = _quiz;
    if (userId == null ||
        answers == null ||
        quiz == null ||
        answers.contains(null)) {
      return;
    }
    final result = _engine.evaluateMicroQuiz(
      userId: userId,
      quizId: quiz.quizId,
      answers: answers,
    );
    setState(() {
      _pendingResult = _compat.applyVisibilityChoice(
        result,
        visibility: _selectedVisibility ?? TruQuizVisibility.privateOnly,
      );
    });
  }

  Future<void> _saveAndContinue() async {
    final result = _pendingResult;
    if (result == null) return;
    final userId = context.read<AppProvider>().currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    await context.read<AppState>().persistQuizResult(
          userId: userId,
          result: _compat.applyVisibilityChoice(
            result,
            visibility: _selectedVisibility ?? TruQuizVisibility.privateOnly,
          ),
        );
    if (!mounted) return;
    context.go(_resolveReturnTo());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final quiz = _quiz;
    final answers = _answers;
    if (quiz == null || answers == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final progress = (_currentStep + 1) / quiz.questions.length;
    final currentQuestion = quiz.questions[_currentStep];
    final selectedIndex = answers[_currentStep];
    final showingResult = _pendingResult != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(quiz.title),
        leading: IconButton(
          onPressed: showingResult
              ? () => setState(() => _pendingResult = null)
              : () => TruNavigation.goBackOrReturn(context),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
        actions: [
          if (!showingResult)
            TextButton(
              onPressed:
                  _isSaving ? null : () => context.go(_resolveReturnTo()),
              child: const Text('Skip'),
            ),
          IconButton(
            onPressed: () => TruNavigation.closeModule(context),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              TruLuraGlassCard(
                radius: 24,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showingResult
                          ? '${quiz.progressLabel} result'
                          : '${quiz.progressLabel} • ${_currentStep + 1} of ${quiz.questions.length}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: showingResult ? 1 : progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      showingResult
                          ? 'Choose how this result should be routed'
                          : quiz.subtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0.08, 0),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: showingResult
                      ? _MicroQuizResultView(
                          key: const ValueKey<String>('micro-quiz-result'),
                          entry: _entry,
                          result: _pendingResult!,
                          selectedVisibility: _selectedVisibility ??
                              TruQuizVisibility.privateOnly,
                          onSelectVisibility: (visibility) {
                            setState(() => _selectedVisibility = visibility);
                          },
                        )
                      : _MicroQuizQuestionView(
                          key: ValueKey<int>(_currentStep),
                          questionNumber: _currentStep + 1,
                          question: currentQuestion,
                          selectedIndex: selectedIndex,
                          onSelected: (value) {
                            setState(() => answers[_currentStep] = value);
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
              if (!showingResult)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving || _currentStep == 0
                            ? null
                            : () => setState(() => _currentStep -= 1),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: selectedIndex == null || _isSaving
                            ? null
                            : _currentStep == quiz.questions.length - 1
                                ? _prepareResult
                                : () => setState(() => _currentStep += 1),
                        child: Text(
                          _currentStep == quiz.questions.length - 1
                              ? 'See result'
                              : 'Next',
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveAndContinue,
                    child: Text(_isSaving ? 'Saving...' : 'Continue'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MicroQuizQuestionView extends StatelessWidget {
  final int questionNumber;
  final TruQuizQuestion question;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const _MicroQuizQuestionView({
    super.key,
    required this.questionNumber,
    required this.question,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return TruLuraGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question $questionNumber',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.prompt,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final option = question.options[index];
                final selected = selectedIndex == index;
                return _MicroQuizAnswerCard(
                  label: option.label,
                  selected: selected,
                  onTap: () => onSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MicroQuizAnswerCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MicroQuizAnswerCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected
              ? cs.primary.withValues(alpha: 0.16)
              : cs.surfaceContainerHighest.withValues(alpha: 0.34),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color:
                  selected ? cs.primary : cs.onSurface.withValues(alpha: 0.46),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicroQuizResultView extends StatelessWidget {
  final TruQuizRegistryEntry? entry;
  final TruQuizResult result;
  final TruQuizVisibility selectedVisibility;
  final ValueChanged<TruQuizVisibility> onSelectVisibility;

  const _MicroQuizResultView({
    super.key,
    required this.entry,
    required this.result,
    required this.selectedVisibility,
    required this.onSelectVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final options = entry?.visibilityOptions ??
        const <TruQuizVisibility>{TruQuizVisibility.privateOnly};

    return ListView(
      children: [
        TruLuraGlassCard(
          radius: 24,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.primaryResult ?? 'Your micro-quiz result',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                result.resultSummary ??
                    'This result helps TruLura tune discovery, prompts, and social pacing.',
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TruLuraGlowPill(
                    label: selectedVisibility.label,
                    selected:
                        selectedVisibility == TruQuizVisibility.profileOptIn,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  if (result.primaryResult != null)
                    TruLuraGlowPill(
                      label: result.primaryResult!,
                      selected: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  if (result.secondaryTraitLabel != null)
                    TruLuraGlowPill(
                      label: result.secondaryTraitLabel!,
                      selected: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                ],
              ),
              if (result.secondaryResult != null) ...[
                const SizedBox(height: 12),
                Text(
                  result.secondaryTraitLabel != null &&
                          result.secondaryTraitLabel!.isNotEmpty
                      ? 'Secondary trait: ${result.secondaryResult} • ${result.secondaryTraitLabel}'
                      : 'Secondary trait: ${result.secondaryResult}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Choose how to save it',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        for (final option in options) ...[
          _ResultActionCard(
            title: option.label,
            subtitle: switch (option) {
              TruQuizVisibility.privateOnly =>
                'Stored in your saved quiz vault and used privately for personalization.',
              TruQuizVisibility.profileOptIn =>
                'Eligible for profile cards and visible when you choose to share quiz results.',
              TruQuizVisibility.matchingOnly =>
                'Used for compatibility and matching without showing on your profile.',
            },
            selected: selectedVisibility == option,
            onTap: () => onSelectVisibility(option),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          'Continue will save your result, answers, completed time, visibility choice, and vault entry.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.72),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ResultActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ResultActionCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected
              ? cs.primary.withValues(alpha: 0.14)
              : cs.surfaceContainerHighest.withValues(alpha: 0.28),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.72),
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color:
                  selected ? cs.primary : cs.onSurface.withValues(alpha: 0.46),
            ),
          ],
        ),
      ),
    );
  }
}
