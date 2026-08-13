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
    final hasMeaningfulProfile = progress >= 72 && discoveryReady;
    final statusLabel = progress < 26
        ? 'Just started'
        : progress < 56
            ? 'Basics added'
            : discoveryReady
                ? (progress >= 88 ? 'Strong profile' : 'Discovery-ready')
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

  bool _hasVibe(User user) {
    return user.vibeLabel != TruVibeLabel.oldSoul || user.moodTags.isNotEmpty;
  }

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
