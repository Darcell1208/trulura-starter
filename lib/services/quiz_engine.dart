import 'package:flutter/foundation.dart';
import 'package:trulura/models/quiz/quiz_registry_models.dart';
import 'package:trulura/models/profile/quiz_result.dart';
import 'package:trulura/services/quiz_registry_service.dart';

@immutable
class TruQuizBlueprint {
  final String quizId;
  final String title;
  final String subtitle;
  final List<TruQuizQuestion> questions;

  const TruQuizBlueprint({
    required this.quizId,
    required this.title,
    required this.subtitle,
    required this.questions,
  });
}

@immutable
class TruQuizQuestion {
  final String prompt;
  final List<TruQuizOption> options;

  const TruQuizQuestion({
    required this.prompt,
    required this.options,
  });
}

@immutable
class TruQuizOption {
  final String label;
  final Map<String, int> traitScores;
  final Map<String, int> discoverySignals;
  final Map<String, int> archetypeScores;

  const TruQuizOption({
    required this.label,
    required this.traitScores,
    this.discoverySignals = const <String, int>{},
    this.archetypeScores = const <String, int>{},
  });
}

@immutable
class TruMicroQuizOutcome {
  final String id;
  final String title;
  final String summary;
  final String secondaryTraitLabel;

  const TruMicroQuizOutcome({
    required this.id,
    required this.title,
    required this.summary,
    required this.secondaryTraitLabel,
  });
}

@immutable
class TruMicroQuizTieBreaker {
  final Set<String> outcomeIds;
  final List<int> questionIndexes;

  const TruMicroQuizTieBreaker({
    required this.outcomeIds,
    required this.questionIndexes,
  });
}

@immutable
class TruMicroQuizBlueprint {
  final String quizId;
  final String title;
  final String subtitle;
  final String progressLabel;
  final List<TruQuizQuestion> questions;
  final List<TruMicroQuizOutcome> outcomes;
  final List<TruMicroQuizTieBreaker> tieBreakers;

  const TruMicroQuizBlueprint({
    required this.quizId,
    required this.title,
    required this.subtitle,
    required this.progressLabel,
    required this.questions,
    required this.outcomes,
    this.tieBreakers = const <TruMicroQuizTieBreaker>[],
  });
}

class TruQuizEngine {
  const TruQuizEngine();

  static const QuizRegistryService _registry = QuizRegistryService();

  static const String friendshipEnergyMatchQuizId =
      'friendship_energy_match_v1';
  static const String socialStyleQuizId = 'social_style_v1';
  static const String compatibilityQuizId = 'compatibility_traits_v1';

  static const TruMicroQuizBlueprint friendshipEnergyMatchBlueprint =
      TruMicroQuizBlueprint(
    quizId: friendshipEnergyMatchQuizId,
    title: 'Friendship Energy Match',
    progressLabel: 'Friendship Energy Match',
    subtitle:
        'A short social-style read so TruLura can better tune friend suggestions, prompts, and feed emphasis.',
    questions: <TruQuizQuestion>[
      TruQuizQuestion(
        prompt: 'When you\'re stressed, what kind of person helps most?',
        options: <TruQuizOption>[
          TruQuizOption(
            label: 'Someone who listens',
            traitScores: <String, int>{
              'secure': 18,
              'emotional': 16,
              'depth': 12,
            },
            discoverySignals: <String, int>{
              'aligned_people': 14,
              'communities': 10,
            },
            archetypeScores: <String, int>{
              'safe_space_friend': 2,
              'soft_loyalist': 1,
            },
          ),
          TruQuizOption(
            label: 'Someone funny',
            traitScores: <String, int>{
              'playful': 20,
              'lifestyle': 10,
              'emotional': 6,
            },
            discoverySignals: <String, int>{
              'social_sparks': 16,
              'communities': 6,
            },
            archetypeScores: <String, int>{
              'chaos_twin': 2,
              'hype_friend': 1,
            },
          ),
          TruQuizOption(
            label: 'Someone distracting',
            traitScores: <String, int>{
              'playful': 14,
              'independence': 12,
              'lifestyle': 10,
            },
            discoverySignals: <String, int>{
              'social_sparks': 12,
              'communities': 6,
            },
            archetypeScores: <String, int>{
              'chaos_twin': 1,
              'hype_friend': 2,
            },
          ),
          TruQuizOption(
            label: 'Someone calm and quiet',
            traitScores: <String, int>{
              'secure': 16,
              'depth': 12,
              'lifestyle': 10,
            },
            discoverySignals: <String, int>{
              'aligned_people': 12,
              'communities': 8,
            },
            archetypeScores: <String, int>{
              'quiet_anchor': 2,
              'soft_loyalist': 1,
            },
          ),
        ],
      ),
      TruQuizQuestion(
        prompt: 'Your ideal friendship feels like:',
        options: <TruQuizOption>[
          TruQuizOption(
            label: 'Deep and honest',
            traitScores: <String, int>{
              'depth': 18,
              'secure': 14,
              'emotional': 12,
            },
            discoverySignals: <String, int>{
              'aligned_people': 12,
              'communities': 10,
            },
            archetypeScores: <String, int>{
              'safe_space_friend': 2,
              'soft_loyalist': 1,
            },
          ),
          TruQuizOption(
            label: 'Playful and chaotic',
            traitScores: <String, int>{
              'playful': 20,
              'lifestyle': 12,
            },
            discoverySignals: <String, int>{
              'social_sparks': 18,
              'communities': 6,
            },
            archetypeScores: <String, int>{
              'chaos_twin': 2,
              'hype_friend': 1,
            },
          ),
          TruQuizOption(
            label: 'Peaceful and easy',
            traitScores: <String, int>{
              'secure': 16,
              'lifestyle': 14,
              'depth': 10,
            },
            discoverySignals: <String, int>{
              'aligned_people': 12,
              'communities': 10,
            },
            archetypeScores: <String, int>{
              'quiet_anchor': 2,
              'soft_loyalist': 1,
            },
          ),
          TruQuizOption(
            label: 'Motivating and uplifting',
            traitScores: <String, int>{
              'playful': 12,
              'secure': 10,
              'intellectual': 8,
            },
            discoverySignals: <String, int>{
              'social_sparks': 12,
              'aligned_people': 8,
            },
            archetypeScores: <String, int>{
              'hype_friend': 2,
              'safe_space_friend': 1,
            },
          ),
        ],
      ),
      TruQuizQuestion(
        prompt: 'You usually open up:',
        options: <TruQuizOption>[
          TruQuizOption(
            label: 'Right away',
            traitScores: <String, int>{
              'playful': 12,
              'emotional': 12,
              'secure': 8,
            },
            discoverySignals: <String, int>{
              'social_sparks': 12,
              'aligned_people': 8,
            },
            archetypeScores: <String, int>{
              'hype_friend': 1,
              'chaos_twin': 1,
              'safe_space_friend': 1,
            },
          ),
          TruQuizOption(
            label: 'After a little time',
            traitScores: <String, int>{
              'secure': 12,
              'depth': 10,
              'lifestyle': 8,
            },
            discoverySignals: <String, int>{
              'aligned_people': 10,
              'communities': 8,
            },
            archetypeScores: <String, int>{
              'soft_loyalist': 2,
              'quiet_anchor': 1,
            },
          ),
          TruQuizOption(
            label: 'Only if I feel safe',
            traitScores: <String, int>{
              'secure': 18,
              'depth': 14,
              'emotional': 10,
            },
            discoverySignals: <String, int>{
              'aligned_people': 14,
              'communities': 8,
            },
            archetypeScores: <String, int>{
              'safe_space_friend': 2,
              'quiet_anchor': 1,
            },
          ),
          TruQuizOption(
            label: 'Mostly through jokes or memes',
            traitScores: <String, int>{
              'playful': 16,
              'independence': 10,
              'lifestyle': 6,
            },
            discoverySignals: <String, int>{
              'social_sparks': 14,
              'communities': 6,
            },
            archetypeScores: <String, int>{
              'chaos_twin': 2,
              'hype_friend': 1,
            },
          ),
        ],
      ),
      TruQuizQuestion(
        prompt: 'Best hangout vibe:',
        options: <TruQuizOption>[
          TruQuizOption(
            label: 'Deep conversation',
            traitScores: <String, int>{
              'depth': 18,
              'intellectual': 12,
              'secure': 10,
            },
            discoverySignals: <String, int>{
              'aligned_people': 12,
              'communities': 8,
            },
            archetypeScores: <String, int>{
              'safe_space_friend': 2,
              'quiet_anchor': 1,
            },
          ),
          TruQuizOption(
            label: 'Spontaneous fun',
            traitScores: <String, int>{
              'playful': 18,
              'lifestyle': 12,
              'independence': 6,
            },
            discoverySignals: <String, int>{
              'social_sparks': 16,
            },
            archetypeScores: <String, int>{
              'chaos_twin': 2,
              'hype_friend': 1,
            },
          ),
          TruQuizOption(
            label: 'Chill silence',
            traitScores: <String, int>{
              'secure': 14,
              'lifestyle': 12,
              'depth': 8,
            },
            discoverySignals: <String, int>{
              'aligned_people': 10,
              'communities': 8,
            },
            archetypeScores: <String, int>{
              'quiet_anchor': 2,
              'soft_loyalist': 1,
            },
          ),
          TruQuizOption(
            label: 'Doing something productive together',
            traitScores: <String, int>{
              'intellectual': 12,
              'lifestyle': 12,
              'secure': 8,
            },
            discoverySignals: <String, int>{
              'aligned_people': 8,
              'communities': 8,
            },
            archetypeScores: <String, int>{
              'soft_loyalist': 2,
              'hype_friend': 1,
            },
          ),
        ],
      ),
    ],
    outcomes: <TruMicroQuizOutcome>[
      TruMicroQuizOutcome(
        id: 'quiet_anchor',
        title: 'Quiet Anchor',
        summary:
            'You bring calm, steady energy and make people feel safe without needing to be loud. You connect best through peace, trust, and grounded presence.',
        secondaryTraitLabel: 'Calm loyalty',
      ),
      TruMicroQuizOutcome(
        id: 'safe_space_friend',
        title: 'Safe Space Friend',
        summary:
            'You value emotional honesty and real connection. People feel like they can exhale around you because you listen, understand, and care deeply.',
        secondaryTraitLabel: 'Deep emotional safety',
      ),
      TruMicroQuizOutcome(
        id: 'soft_loyalist',
        title: 'Soft Loyalist',
        summary:
            'You may take time to open up, but once you do, your care runs deep. You build friendship through consistency, trust, and genuine effort.',
        secondaryTraitLabel: 'Gentle steadiness',
      ),
      TruMicroQuizOutcome(
        id: 'chaos_twin',
        title: 'Chaos Twin',
        summary:
            'You connect through humor, spontaneity, and unpredictable fun. Your best friendships feel alive, unfiltered, and full of inside jokes.',
        secondaryTraitLabel: 'Playful energy',
      ),
      TruMicroQuizOutcome(
        id: 'hype_friend',
        title: 'Hype Friend',
        summary:
            'You bring uplifting energy and momentum into people\'s lives. You thrive in friendships that feel encouraging, expressive, and emotionally energizing.',
        secondaryTraitLabel: 'Uplifting momentum',
      ),
    ],
    tieBreakers: <TruMicroQuizTieBreaker>[
      TruMicroQuizTieBreaker(
        outcomeIds: <String>{'quiet_anchor', 'safe_space_friend'},
        questionIndexes: <int>[3],
      ),
      TruMicroQuizTieBreaker(
        outcomeIds: <String>{'chaos_twin', 'hype_friend'},
        questionIndexes: <int>[1],
      ),
      TruMicroQuizTieBreaker(
        outcomeIds: <String>{'soft_loyalist', 'quiet_anchor'},
        questionIndexes: <int>[2],
      ),
    ],
  );

  static const TruMicroQuizBlueprint socialStyleBlueprint =
      TruMicroQuizBlueprint(
    quizId: socialStyleQuizId,
    title: 'Social Style',
    progressLabel: 'Social Style',
    subtitle:
        'A quick read on how your energy moves through people, posting, and connection pacing.',
    questions: <TruQuizQuestion>[
      TruQuizQuestion(
        prompt: 'In a group, you\'re usually:',
        options: <TruQuizOption>[
          TruQuizOption(
            label: 'Talking to everyone',
            traitScores: <String, int>{
              'playful': 16,
              'lifestyle': 14,
              'secure': 8,
            },
            discoverySignals: <String, int>{
              'social_sparks': 16,
              'communities': 10,
            },
            archetypeScores: <String, int>{
              'social_butterfly': 2,
              'balanced_drifter': 1,
            },
          ),
          TruQuizOption(
            label: 'Observing first',
            traitScores: <String, int>{
              'secure': 12,
              'depth': 10,
              'emotional': 12,
            },
            discoverySignals: <String, int>{
              'aligned_people': 12,
              'communities': 8,
            },
            archetypeScores: <String, int>{
              'warm_observer': 2,
              'private_glow': 1,
            },
          ),
          TruQuizOption(
            label: 'Sticking to one or two people',
            traitScores: <String, int>{
              'depth': 14,
              'secure': 12,
              'independence': 8,
            },
            discoverySignals: <String, int>{
              'aligned_people': 12,
              'communities': 6,
            },
            archetypeScores: <String, int>{
              'selective_connector': 2,
              'private_glow': 1,
            },
          ),
          TruQuizOption(
            label: 'Floating in and out',
            traitScores: <String, int>{
              'playful': 12,
              'lifestyle': 14,
              'independence': 10,
            },
            discoverySignals: <String, int>{
              'social_sparks': 12,
              'communities': 10,
            },
            archetypeScores: <String, int>{
              'balanced_drifter': 2,
              'social_butterfly': 1,
            },
          ),
        ],
      ),
      TruQuizQuestion(
        prompt: 'Posting online feels:',
        options: <TruQuizOption>[
          TruQuizOption(
            label: 'Natural',
            traitScores: <String, int>{
              'playful': 16,
              'lifestyle': 12,
              'secure': 8,
            },
            discoverySignals: <String, int>{
              'social_sparks': 14,
              'communities': 10,
            },
            archetypeScores: <String, int>{
              'social_butterfly': 2,
              'balanced_drifter': 1,
            },
          ),
          TruQuizOption(
            label: 'Fun sometimes',
            traitScores: <String, int>{
              'playful': 12,
              'lifestyle': 12,
              'secure': 10,
            },
            discoverySignals: <String, int>{
              'social_sparks': 10,
              'communities': 8,
            },
            archetypeScores: <String, int>{
              'balanced_drifter': 2,
              'warm_observer': 1,
            },
          ),
          TruQuizOption(
            label: 'Vulnerable',
            traitScores: <String, int>{
              'emotional': 14,
              'secure': 10,
              'depth': 12,
            },
            discoverySignals: <String, int>{
              'aligned_people': 12,
              'communities': 6,
            },
            archetypeScores: <String, int>{
              'warm_observer': 2,
              'selective_connector': 1,
            },
          ),
          TruQuizOption(
            label: 'Not really my thing',
            traitScores: <String, int>{
              'independence': 12,
              'secure': 12,
              'depth': 10,
            },
            discoverySignals: <String, int>{
              'aligned_people': 10,
              'communities': 4,
            },
            archetypeScores: <String, int>{
              'private_glow': 2,
              'selective_connector': 1,
            },
          ),
        ],
      ),
      TruQuizQuestion(
        prompt: 'You prefer people who:',
        options: <TruQuizOption>[
          TruQuizOption(
            label: 'Reach out first',
            traitScores: <String, int>{
              'emotional': 12,
              'secure': 14,
              'depth': 8,
            },
            discoverySignals: <String, int>{
              'aligned_people': 10,
              'communities': 6,
            },
            archetypeScores: <String, int>{
              'warm_observer': 2,
              'private_glow': 1,
            },
          ),
          TruQuizOption(
            label: 'Respect space',
            traitScores: <String, int>{
              'independence': 14,
              'secure': 12,
              'depth': 8,
            },
            discoverySignals: <String, int>{
              'aligned_people': 10,
              'communities': 4,
            },
            archetypeScores: <String, int>{
              'private_glow': 2,
              'selective_connector': 1,
            },
          ),
          TruQuizOption(
            label: 'Keep it light',
            traitScores: <String, int>{
              'playful': 16,
              'lifestyle': 10,
              'secure': 6,
            },
            discoverySignals: <String, int>{
              'social_sparks': 14,
              'communities': 8,
            },
            archetypeScores: <String, int>{
              'social_butterfly': 2,
              'balanced_drifter': 1,
            },
          ),
          TruQuizOption(
            label: 'Go deep',
            traitScores: <String, int>{
              'depth': 16,
              'emotional': 10,
              'secure': 8,
            },
            discoverySignals: <String, int>{
              'aligned_people': 12,
              'communities': 6,
            },
            archetypeScores: <String, int>{
              'selective_connector': 2,
              'warm_observer': 1,
            },
          ),
        ],
      ),
      TruQuizQuestion(
        prompt: 'Your energy is more:',
        options: <TruQuizOption>[
          TruQuizOption(
            label: 'Public',
            traitScores: <String, int>{
              'playful': 16,
              'lifestyle': 12,
            },
            discoverySignals: <String, int>{
              'social_sparks': 14,
              'communities': 8,
            },
            archetypeScores: <String, int>{
              'social_butterfly': 2,
            },
          ),
          TruQuizOption(
            label: 'Balanced',
            traitScores: <String, int>{
              'lifestyle': 12,
              'secure': 10,
              'independence': 10,
            },
            discoverySignals: <String, int>{
              'social_sparks': 8,
              'communities': 8,
            },
            archetypeScores: <String, int>{
              'balanced_drifter': 2,
            },
          ),
          TruQuizOption(
            label: 'Private',
            traitScores: <String, int>{
              'independence': 14,
              'secure': 12,
            },
            discoverySignals: <String, int>{
              'aligned_people': 8,
              'communities': 4,
            },
            archetypeScores: <String, int>{
              'private_glow': 2,
            },
          ),
          TruQuizOption(
            label: 'Depends on my mood',
            traitScores: <String, int>{
              'secure': 10,
              'lifestyle': 10,
              'depth': 8,
            },
            discoverySignals: <String, int>{
              'aligned_people': 8,
              'social_sparks': 8,
            },
            archetypeScores: <String, int>{
              'warm_observer': 1,
              'selective_connector': 1,
              'balanced_drifter': 1,
            },
          ),
        ],
      ),
      TruQuizQuestion(
        prompt: 'When meeting new people, you usually:',
        options: <TruQuizOption>[
          TruQuizOption(
            label: 'Jump right in',
            traitScores: <String, int>{
              'playful': 16,
              'secure': 8,
              'lifestyle': 12,
            },
            discoverySignals: <String, int>{
              'social_sparks': 14,
              'communities': 8,
            },
            archetypeScores: <String, int>{
              'social_butterfly': 2,
              'balanced_drifter': 1,
            },
          ),
          TruQuizOption(
            label: 'Warm up slowly',
            traitScores: <String, int>{
              'secure': 14,
              'depth': 10,
              'emotional': 10,
            },
            discoverySignals: <String, int>{
              'aligned_people': 10,
              'communities': 6,
            },
            archetypeScores: <String, int>{
              'warm_observer': 2,
              'selective_connector': 1,
            },
          ),
          TruQuizOption(
            label: 'Let them come to you',
            traitScores: <String, int>{
              'independence': 14,
              'secure': 12,
              'depth': 8,
            },
            discoverySignals: <String, int>{
              'aligned_people': 10,
              'communities': 4,
            },
            archetypeScores: <String, int>{
              'private_glow': 2,
              'warm_observer': 1,
            },
          ),
          TruQuizOption(
            label: 'Match the vibe first',
            traitScores: <String, int>{
              'lifestyle': 12,
              'secure': 10,
              'independence': 8,
            },
            discoverySignals: <String, int>{
              'social_sparks': 8,
              'aligned_people': 8,
            },
            archetypeScores: <String, int>{
              'balanced_drifter': 2,
              'selective_connector': 1,
            },
          ),
        ],
      ),
    ],
    outcomes: <TruMicroQuizOutcome>[
      TruMicroQuizOutcome(
        id: 'social_butterfly',
        title: 'Social Butterfly',
        summary:
            'You move easily through people, energy, and conversation. You thrive in spaces that are active, expressive, and socially alive.',
        secondaryTraitLabel: 'Open energy',
      ),
      TruMicroQuizOutcome(
        id: 'warm_observer',
        title: 'Warm Observer',
        summary:
            'You notice everything before you open fully. You connect through quiet warmth, safety, and thoughtful energy rather than loud presence.',
        secondaryTraitLabel: 'Gentle presence',
      ),
      TruMicroQuizOutcome(
        id: 'selective_connector',
        title: 'Selective Connector',
        summary:
            'You do not need everyone. You value depth, intention, and meaningful connection with the right people over broad social attention.',
        secondaryTraitLabel: 'Depth first',
      ),
      TruMicroQuizOutcome(
        id: 'private_glow',
        title: 'Private Glow',
        summary:
            'Your energy is real, but not always public. You connect best when people respect your space and let trust build naturally.',
        secondaryTraitLabel: 'Quiet boundaries',
      ),
      TruMicroQuizOutcome(
        id: 'balanced_drifter',
        title: 'Balanced Drifter',
        summary:
            'You adapt to the room and move where the energy feels right. You like freedom, flexibility, and connections that do not feel forced.',
        secondaryTraitLabel: 'Flexible rhythm',
      ),
    ],
    tieBreakers: <TruMicroQuizTieBreaker>[
      TruMicroQuizTieBreaker(
        outcomeIds: <String>{'social_butterfly', 'balanced_drifter'},
        questionIndexes: <int>[0, 3],
      ),
      TruMicroQuizTieBreaker(
        outcomeIds: <String>{'warm_observer', 'private_glow'},
        questionIndexes: <int>[1, 4],
      ),
      TruMicroQuizTieBreaker(
        outcomeIds: <String>{'selective_connector', 'warm_observer'},
        questionIndexes: <int>[2],
      ),
    ],
  );

  static const List<TruMicroQuizBlueprint> microQuizCatalog =
      <TruMicroQuizBlueprint>[
    friendshipEnergyMatchBlueprint,
    socialStyleBlueprint,
  ];

  static final Map<String, TruQuizBlueprint> _quizBlueprintsById =
      <String, TruQuizBlueprint>{
    compatibilityBlueprint.quizId: compatibilityBlueprint,
  };

  static const TruQuizBlueprint compatibilityBlueprint = TruQuizBlueprint(
    quizId: compatibilityQuizId,
    title: 'Personalization Quiz',
    subtitle:
        'A short quiz to help Aura tune your feed, communities, and connection surfaces.',
    questions: <TruQuizQuestion>[
      TruQuizQuestion(
        prompt: 'What kind of connection feels best right now?',
        options: <TruQuizOption>[
          TruQuizOption(
            label: 'Steady and emotionally safe',
            traitScores: <String, int>{
              'emotional': 28,
              'secure': 24,
              'depth': 10,
            },
            discoverySignals: <String, int>{
              'aligned_people': 14,
              'communities': 10,
            },
          ),
          TruQuizOption(
            label: 'Curious and mentally engaging',
            traitScores: <String, int>{
              'intellectual': 28,
              'depth': 18,
              'independence': 10,
            },
            discoverySignals: <String, int>{
              'communities': 16,
              'aligned_people': 10,
            },
          ),
          TruQuizOption(
            label: 'Light, social, and energizing',
            traitScores: <String, int>{
              'playful': 24,
              'lifestyle': 18,
              'emotional': 10,
            },
            discoverySignals: <String, int>{
              'social_sparks': 18,
              'communities': 8,
            },
          ),
        ],
      ),
      TruQuizQuestion(
        prompt: 'What kind of spaces are you most drawn to?',
        options: <TruQuizOption>[
          TruQuizOption(
            label: 'Thoughtful small groups',
            traitScores: <String, int>{
              'depth': 22,
              'emotional': 16,
              'intellectual': 12,
            },
            discoverySignals: <String, int>{
              'communities': 18,
              'aligned_people': 8,
            },
          ),
          TruQuizOption(
            label: 'One-on-one conversations',
            traitScores: <String, int>{
              'secure': 20,
              'intellectual': 14,
              'emotional': 16,
            },
            discoverySignals: <String, int>{
              'aligned_people': 16,
              'communities': 6,
            },
          ),
          TruQuizOption(
            label: 'Events with fun social momentum',
            traitScores: <String, int>{
              'playful': 20,
              'lifestyle': 16,
              'independence': 10,
            },
            discoverySignals: <String, int>{
              'social_sparks': 16,
              'communities': 8,
            },
          ),
        ],
      ),
      TruQuizQuestion(
        prompt: 'How do you usually like to discover new people?',
        options: <TruQuizOption>[
          TruQuizOption(
            label: 'Through trusted mutuals',
            traitScores: <String, int>{
              'secure': 22,
              'emotional': 14,
              'lifestyle': 12,
            },
            discoverySignals: <String, int>{
              'aligned_people': 18,
              'communities': 6,
            },
          ),
          TruQuizOption(
            label: 'Through aligned interests and ideas',
            traitScores: <String, int>{
              'intellectual': 20,
              'depth': 18,
              'lifestyle': 10,
            },
            discoverySignals: <String, int>{
              'communities': 18,
              'aligned_people': 10,
            },
          ),
          TruQuizOption(
            label: 'Through spontaneous sparks',
            traitScores: <String, int>{
              'playful': 22,
              'independence': 14,
              'lifestyle': 12,
            },
            discoverySignals: <String, int>{
              'social_sparks': 20,
              'aligned_people': 6,
            },
          ),
        ],
      ),
      TruQuizQuestion(
        prompt: 'What pace feels healthiest right now?',
        options: <TruQuizOption>[
          TruQuizOption(
            label: 'Slow, grounded, and intentional',
            traitScores: <String, int>{
              'secure': 18,
              'emotional': 18,
              'lifestyle': 10,
            },
            discoverySignals: <String, int>{
              'aligned_people': 12,
              'communities': 10,
            },
          ),
          TruQuizOption(
            label: 'Balanced with room to explore',
            traitScores: <String, int>{
              'intellectual': 14,
              'lifestyle': 16,
              'depth': 12,
            },
            discoverySignals: <String, int>{
              'communities': 12,
              'social_sparks': 8,
            },
          ),
          TruQuizOption(
            label: 'Independent with room to dip in and out',
            traitScores: <String, int>{
              'independence': 20,
              'playful': 14,
              'lifestyle': 12,
            },
            discoverySignals: <String, int>{
              'social_sparks': 12,
              'aligned_people': 8,
            },
          ),
        ],
      ),
    ],
  );

  TruQuizResult evaluateCompatibilityQuiz({
    required String userId,
    required List<int?> answers,
    String quizId = compatibilityQuizId,
  }) {
    final blueprint = quizBlueprintById(quizId);
    final registryEntry = _registry.byId(blueprint.quizId);
    final totals = <String, int>{
      'emotional': 40,
      'intellectual': 40,
      'lifestyle': 40,
      'secure': 40,
      'playful': 40,
      'depth': 40,
      'independence': 40,
    };
    final discovery = <String, int>{
      'communities': 40,
      'aligned_people': 40,
      'social_sparks': 40,
    };

    for (var i = 0; i < blueprint.questions.length; i += 1) {
      final selectedIndex = answers.elementAt(i);
      if (selectedIndex == null) continue;
      final option = blueprint.questions[i].options[selectedIndex];
      for (final entry in option.traitScores.entries) {
        totals.update(
          entry.key,
          (value) => (value + entry.value).clamp(0, 100),
        );
      }
      for (final entry in option.discoverySignals.entries) {
        discovery.update(
          entry.key,
          (value) => (value + entry.value).clamp(0, 100),
        );
      }
    }

    final now = DateTime.now();
    return TruQuizResult(
      userId: userId,
      quizId: blueprint.quizId,
      quizType: TruQuizType.compatibilityTraits,
      completionLevel: TruQuizCompletionLevel.deeper,
      category: registryEntry?.category ?? TruQuizCategory.advanced,
      ledgerState: registryEntry?.ledgerState ?? TruQuizLedgerState.recovery,
      resultType: registryEntry?.resultType ?? TruQuizResultType.compatibility,
      traitScores: totals,
      discoverySignals: discovery,
      answerIndexes: answers.whereType<int>().toList(growable: false),
      visibility:
          registryEntry?.visibilityDefault ?? TruQuizVisibility.privateOnly,
      savedToVault: registryEntry?.saveToVaultByDefault ?? true,
      selectedForProfileCard: false,
      includeInMatching:
          registryEntry?.visibilityDefault == TruQuizVisibility.matchingOnly,
      routedEffects: registryEntry?.effects.toList(growable: false) ??
          const <TruQuizEffect>[],
      createdAt: now,
      updatedAt: now,
    );
  }

  TruQuizBlueprint quizBlueprintById(String quizId) {
    return _quizBlueprintsById[quizId] ?? compatibilityBlueprint;
  }

  TruMicroQuizBlueprint microQuizById(String quizId) {
    return microQuizCatalog.firstWhere(
      (quiz) => quiz.quizId == quizId,
      orElse: () => friendshipEnergyMatchBlueprint,
    );
  }

  TruMicroQuizOutcome outcomeFor({
    required TruMicroQuizBlueprint quiz,
    required String outcomeId,
  }) {
    return quiz.outcomes.firstWhere(
      (outcome) => outcome.id == outcomeId,
      orElse: () => quiz.outcomes.first,
    );
  }

  TruQuizResult evaluateMicroQuiz({
    required String userId,
    required String quizId,
    required List<int?> answers,
  }) {
    final quiz = microQuizById(quizId);
    final registryEntry = _registry.byId(quizId);
    final totals = <String, int>{
      'emotional': 45,
      'intellectual': 45,
      'lifestyle': 45,
      'secure': 45,
      'playful': 45,
      'depth': 45,
      'independence': 45,
    };
    final discovery = <String, int>{
      'communities': 45,
      'aligned_people': 45,
      'social_sparks': 45,
    };
    final archetypes = <String, int>{
      for (final outcome in quiz.outcomes) outcome.id: 0,
    };
    final plusTwoCounts = <String, int>{
      for (final outcome in quiz.outcomes) outcome.id: 0,
    };

    for (var i = 0; i < quiz.questions.length; i += 1) {
      final selectedIndex = answers.elementAt(i);
      if (selectedIndex == null) continue;
      final option = quiz.questions[i].options[selectedIndex];
      for (final entry in option.traitScores.entries) {
        totals.update(
          entry.key,
          (value) => (value + entry.value).clamp(0, 100),
        );
      }
      for (final entry in option.discoverySignals.entries) {
        discovery.update(
          entry.key,
          (value) => (value + entry.value).clamp(0, 100),
        );
      }
      for (final entry in option.archetypeScores.entries) {
        archetypes.update(
          entry.key,
          (value) => value + entry.value,
          ifAbsent: () => entry.value,
        );
        if (entry.value >= 2) {
          plusTwoCounts.update(entry.key, (value) => value + 1,
              ifAbsent: () => 1);
        }
      }
    }

    final topScore = archetypes.values.fold<int>(
      0,
      (maxSoFar, value) => value > maxSoFar ? value : maxSoFar,
    );
    final runningScores = <String, int>{
      for (final outcome in quiz.outcomes) outcome.id: 0,
    };
    final firstReachedTopAt = <String, int>{
      for (final outcome in quiz.outcomes)
        outcome.id: quiz.questions.length + 1,
    };

    for (var i = 0; i < quiz.questions.length; i += 1) {
      final selectedIndex = answers.elementAt(i);
      if (selectedIndex == null) continue;
      final option = quiz.questions[i].options[selectedIndex];
      for (final entry in option.archetypeScores.entries) {
        final nextValue = (runningScores[entry.key] ?? 0) + entry.value;
        runningScores[entry.key] = nextValue;
        if (nextValue >= topScore &&
            (firstReachedTopAt[entry.key] ?? quiz.questions.length + 1) > i) {
          firstReachedTopAt[entry.key] = i;
        }
      }
    }

    int compareArchetypes(String leftId, String rightId) {
      final scoreCompare =
          (archetypes[rightId] ?? 0).compareTo(archetypes[leftId] ?? 0);
      if (scoreCompare != 0) return scoreCompare;

      int comparePairwiseQuestions(List<int> questionIndexes) {
        var leftScore = 0;
        var rightScore = 0;
        for (final questionIndex in questionIndexes) {
          final selectedIndex = answers.elementAt(questionIndex);
          if (selectedIndex == null) continue;
          final option = quiz.questions[questionIndex].options[selectedIndex];
          leftScore += option.archetypeScores[leftId] ?? 0;
          rightScore += option.archetypeScores[rightId] ?? 0;
        }
        return rightScore.compareTo(leftScore);
      }

      final pair = <String>{leftId, rightId};
      for (final tieBreaker in quiz.tieBreakers) {
        if (!setEquals(pair, tieBreaker.outcomeIds)) continue;
        final result = comparePairwiseQuestions(tieBreaker.questionIndexes);
        if (result != 0) return result;
      }

      final plusTwoCompare =
          (plusTwoCounts[rightId] ?? 0).compareTo(plusTwoCounts[leftId] ?? 0);
      if (plusTwoCompare != 0) return plusTwoCompare;

      final reachCompare = (firstReachedTopAt[leftId] ??
              quiz.questions.length + 1)
          .compareTo(firstReachedTopAt[rightId] ?? quiz.questions.length + 1);
      if (reachCompare != 0) return reachCompare;

      final leftIndex =
          quiz.outcomes.indexWhere((outcome) => outcome.id == leftId);
      final rightIndex =
          quiz.outcomes.indexWhere((outcome) => outcome.id == rightId);
      return leftIndex.compareTo(rightIndex);
    }

    final orderedOutcomeIds = quiz.outcomes
        .map((outcome) => outcome.id)
        .toList(growable: false)
      ..sort(compareArchetypes);

    final primaryOutcome = outcomeFor(
      quiz: quiz,
      outcomeId: orderedOutcomeIds.first,
    );
    final secondaryOutcome = outcomeFor(
      quiz: quiz,
      outcomeId: orderedOutcomeIds.length > 1
          ? orderedOutcomeIds[1]
          : orderedOutcomeIds.first,
    );

    final now = DateTime.now();
    return TruQuizResult(
      userId: userId,
      quizId: quiz.quizId,
      quizType: TruQuizType.compatibilityTraits,
      completionLevel: TruQuizCompletionLevel.micro,
      category: registryEntry?.category ?? TruQuizCategory.social,
      ledgerState: registryEntry?.ledgerState ?? TruQuizLedgerState.recovery,
      resultType: registryEntry?.resultType ?? TruQuizResultType.archetype,
      traitScores: totals,
      discoverySignals: discovery,
      answerIndexes: answers.whereType<int>().toList(growable: false),
      primaryResult: primaryOutcome.title,
      secondaryResult: secondaryOutcome.title,
      secondaryTraitLabel: secondaryOutcome.secondaryTraitLabel,
      resultSummary: primaryOutcome.summary,
      visibility:
          registryEntry?.visibilityDefault ?? TruQuizVisibility.privateOnly,
      savedToVault: registryEntry?.saveToVaultByDefault ?? true,
      selectedForProfileCard: false,
      includeInMatching: false,
      routedEffects: registryEntry?.effects.toList(growable: false) ??
          const <TruQuizEffect>[],
      createdAt: now,
      updatedAt: now,
    );
  }
}
