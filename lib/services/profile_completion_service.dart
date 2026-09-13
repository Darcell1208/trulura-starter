import 'package:trulura/models/user.dart';

class TruProfileCompletionSummary {
  final int percent;
  final bool hasMeaningfulProfile;
  final bool basicsComplete;
  final bool identityComplete;
  final bool lifestyleComplete;
  final bool expressionComplete;
  final bool discoveryReady;
  final String statusLabel;

  const TruProfileCompletionSummary({
    required this.percent,
    required this.hasMeaningfulProfile,
    required this.basicsComplete,
    required this.identityComplete,
    required this.lifestyleComplete,
    required this.expressionComplete,
    required this.discoveryReady,
    required this.statusLabel,
  });
}

class ProfileCompletionService {
  const ProfileCompletionService();

  List<String> remainingGuidedFields(User? user, {int maxItems = 3}) {
    if (user == null) {
      return const ['username', 'bio', 'photo'];
    }

    final missing = <String>[
      if (user.username.trim().isEmpty) 'username',
      if ((user.bio ?? '').trim().isEmpty) 'bio',
      if ((user.profileImage ?? '').trim().isEmpty) 'photo',
      if (!_hasVibe(user)) 'vibe',
      if (user.intents.isEmpty) 'intent',
      if (user.interests.isEmpty) 'interests',
      if (!_hasExpression(user)) 'prompt or short post',
    ];
    if (missing.length <= maxItems) return missing;
    return missing.take(maxItems).toList(growable: false);
  }

  String nextStepCopy(User? user, {int maxItems = 3}) {
    final missing = remainingGuidedFields(user, maxItems: maxItems);
    if (missing.isEmpty) {
      return 'Your current basics, identity, lifestyle, and expression layers are in place.';
    }
    return 'Next: ${_humanizeList(missing)}.';
  }

  List<String> breakdownLabels(TruProfileCompletionSummary summary) {
    return <String>[
      'Basics ${summary.basicsComplete ? 'done' : 'missing'}',
      'Identity ${summary.identityComplete ? 'done' : 'missing'}',
      'Lifestyle ${summary.lifestyleComplete ? 'done' : 'missing'}',
      'Expression ${summary.expressionComplete ? 'done' : 'missing'}',
    ];
  }

  TruProfileCompletionSummary summarize(User? user) {
    if (user == null) {
      return const TruProfileCompletionSummary(
        percent: 0,
        hasMeaningfulProfile: false,
        basicsComplete: false,
        identityComplete: false,
        lifestyleComplete: false,
        expressionComplete: false,
        discoveryReady: false,
        statusLabel: 'Just started',
      );
    }

    final hasUsername = user.username.trim().isNotEmpty;
    final hasBio = (user.bio ?? '').trim().isNotEmpty;
    final hasPhoto = (user.profileImage ?? '').trim().isNotEmpty;
    final hasBasics = hasUsername && hasBio;

    final hasVibe = _hasVibe(user);
    final hasIdentity = hasVibe;

    final hasInterests = user.interests.isNotEmpty;
    final hasSocialPreference =
        (user.socialPreference ?? '').trim().isNotEmpty;
    final hasIntent = user.intents.isNotEmpty;
    final hasLifestyle = hasInterests && (hasSocialPreference || hasIntent);

    final hasExpression = _hasExpression(user);

    var progress = 0;
    if (hasUsername) progress += 16;
    if (hasBio) progress += 16;
    if (hasPhoto) progress += 12;
    if (hasVibe) progress += 12;
    if (hasInterests) progress += 16;
    if (hasSocialPreference) progress += 10;
    if (hasIntent) progress += 10;
    if (hasExpression) progress += 8;

    final discoveryReady =
        hasUsername &&
        hasBio &&
        hasPhoto &&
        hasIdentity &&
        hasInterests &&
        (hasIntent || hasSocialPreference) &&
        hasExpression;
    // Discovery-ready already requires fields worth at least 90 points, so the
    // old `progress >= 72` guard could never fail and the 'Discovery-ready'
    // tier (below 88) could never show. Both removed rather than retuned:
    // loosening what counts as discovery-ready is a separate product question.
    final hasMeaningfulProfile = discoveryReady;

    // Derived from the same section checks breakdownLabels reports, so the
    // status cannot claim a section the breakdown lists as missing. It used to
    // come from percentage cut-offs, which put "Basics added" beside "Basics
    // missing" on any 26-55% profile without a bio.
    final sectionsDone = <bool>[
      hasBasics,
      hasIdentity,
      hasLifestyle,
      hasExpression,
    ].where((done) => done).length;
    final statusLabel = discoveryReady
        ? 'Strong profile'
        : sectionsDone == 0
            ? 'Just started'
            : hasBasics && sectionsDone == 1
                ? 'Basics added'
                : 'Building discovery';

    return TruProfileCompletionSummary(
      percent: progress.clamp(0, 100),
      hasMeaningfulProfile: hasMeaningfulProfile,
      basicsComplete: hasBasics,
      identityComplete: hasIdentity,
      lifestyleComplete: hasLifestyle,
      expressionComplete: hasExpression,
      discoveryReady: discoveryReady,
      statusLabel: statusLabel,
    );
  }

  /// Vibe only. `user.moodTags` is hydrated from `profiles.vibe`.
  ///
  /// This used to also accept a non-default temperament as evidence of Vibe,
  /// which is one concept's storage scoring another -- the rule in
  /// TruLura_PO_Decision_Vibe_And_Temperament.md. An empty vibe scores zero
  /// whatever the temperament is.
  bool _hasVibe(User user) => user.moodTags.isNotEmpty;

  bool _hasExpression(User user) {
    return (user.expressionPromptAnswer ?? '').trim().isNotEmpty ||
        (user.expressionVibeTag ?? '').trim().isNotEmpty ||
        (user.expressionShortPost ?? '').trim().isNotEmpty;
  }

  String _humanizeList(List<String> values) {
    if (values.isEmpty) return '';
    if (values.length == 1) return values.first;
    if (values.length == 2) return '${values.first} and ${values.last}';
    final head = values.sublist(0, values.length - 1).join(', ');
    return '$head, and ${values.last}';
  }
}
