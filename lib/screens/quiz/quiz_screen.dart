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

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const TruQuizEngine _engine = TruQuizEngine();
  static const QuizRegistryService _registry = QuizRegistryService();
  static final CompatibilityService _compat = CompatibilityService();

  TruQuizBlueprint? _quiz;
  TruQuizRegistryEntry? _entry;
  List<int?>? _answers;
  TruQuizResult? _pendingResult;
  TruQuizVisibility? _selectedVisibility;
  bool _isSaving = false;
  int _currentStep = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_quiz != null && _answers != null) return;
    final quizId = _quizIdFromRoute();
    final quiz = _engine.quizBlueprintById(quizId);
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
    return TruQuizEngine.compatibilityBlueprint.quizId;
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
    final result = _engine.evaluateCompatibilityQuiz(
      userId: userId,
      answers: answers,
      quizId: quiz.quizId,
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

    final showingResult = _pendingResult != null;
    final progress = (_currentStep + 1) / quiz.questions.length;
    final currentQuestion = quiz.questions[_currentStep];
    final selectedIndex = answers[_currentStep];

    return Scaffold(
      appBar: AppBar(
        title: Text(_entry?.title ?? quiz.title),
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
              child: const Text('Later'),
            ),
          IconButton(
            onPressed: () => TruNavigation.closeModule(context),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            TruLuraGlassCard(
              radius: 24,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showingResult
                        ? '${_entry?.category.meta.label ?? 'Quiz'} result'
                        : 'Step ${_currentStep + 1} of ${quiz.questions.length}',
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
                    _entry?.subtitle ?? quiz.subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    showingResult
                        ? 'Choose how this result should live across your profile, vault, and matching surfaces.'
                        : 'This quiz now runs from the master registry, so it can scale with the rest of the library instead of staying tied to a one-off flow.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.72),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!showingResult)
              _QuestionCard(
                index: _currentStep + 1,
                question: currentQuestion,
                selectedIndex: selectedIndex,
                onSelected: (value) {
                  setState(() => answers[_currentStep] = value);
                },
              )
            else
              _ResultSaveCard(
                entry: _entry,
                result: _pendingResult!,
                selectedVisibility:
                    _selectedVisibility ?? TruQuizVisibility.privateOnly,
                onSelectVisibility: (visibility) {
                  setState(() => _selectedVisibility = visibility);
                },
              ),
            const SizedBox(height: 16),
            if (!showingResult)
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => setState(() => _currentStep -= 1),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
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
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final TruQuizQuestion question;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return TruLuraGlassCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question $index',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.prompt,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          RadioGroup<int>(
            groupValue: selectedIndex,
            onChanged: (value) {
              if (value != null) onSelected(value);
            },
            child: Column(
              children: [
                for (var i = 0; i < question.options.length; i += 1)
                  RadioListTile<int>(
                    value: i,
                    contentPadding: EdgeInsets.zero,
                    title: Text(question.options[i].label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultSaveCard extends StatelessWidget {
  final TruQuizRegistryEntry? entry;
  final TruQuizResult result;
  final TruQuizVisibility selectedVisibility;
  final ValueChanged<TruQuizVisibility> onSelectVisibility;

  const _ResultSaveCard({
    required this.entry,
    required this.result,
    required this.selectedVisibility,
    required this.onSelectVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final visibilityOptions =
        entry?.visibilityOptions ?? const <TruQuizVisibility>{};
    final options = visibilityOptions.isEmpty
        ? const <TruQuizVisibility>{TruQuizVisibility.privateOnly}
        : visibilityOptions;

    return TruLuraGlassCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.primaryResult ?? entry?.title ?? 'Quiz result',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.resultSummary ??
                'This result can now route into the right category surfaces without needing bespoke screen logic.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.78),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Save visibility',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (final option in options) ...[
            _VisibilityOptionCard(
              title: option.label,
              subtitle: switch (option) {
                TruQuizVisibility.privateOnly =>
                  'Kept in your saved quiz vault and used for internal personalization only.',
                TruQuizVisibility.profileOptIn =>
                  'Eligible for profile cards and visible wherever you choose to show quiz results.',
                TruQuizVisibility.matchingOnly =>
                  'Used for compatibility and matching surfaces without showing publicly on profile.',
              },
              selected: selectedVisibility == option,
              onTap: () => onSelectVisibility(option),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _VisibilityOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _VisibilityOptionCard({
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
