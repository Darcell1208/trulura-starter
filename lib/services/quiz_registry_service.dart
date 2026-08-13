import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/models/quiz/quiz_registry_models.dart';
import 'package:trulura/services/deep_quiz_archive_service.dart';
import 'package:trulura/services/quiz_engine.dart';

class QuizRegistryService {
  const QuizRegistryService();

  static final List<TruQuizRegistryEntry> _entries = _buildEntries();

  List<TruQuizRegistryEntry> all() =>
      [..._entries]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  List<TruQuizRegistryEntry> byCategory(TruQuizCategory category) {
    return all()
        .where((entry) => entry.category == category)
        .toList(growable: false);
  }

  List<TruQuizRegistryEntry> byLedgerState(TruQuizLedgerState state) {
    return all()
        .where((entry) => entry.ledgerState == state)
        .toList(growable: false);
  }

  List<TruQuizRegistryEntry> readyByCategory(TruQuizCategory category) {
    return byCategory(category)
        .where((entry) => entry.isReady)
        .toList(growable: false);
  }

  List<TruQuizRegistryEntry> bySurface(TruQuizLauncherSurface surface) {
    return all()
        .where((entry) => entry.launcherSurfaces.contains(surface))
        .toList(growable: false);
  }

  List<TruQuizRegistryEntry> byEffect(TruQuizEffect effect) {
    return all()
        .where((entry) => entry.effects.contains(effect))
        .toList(growable: false);
  }

  List<TruQuizRegistryEntry> vaultEligible() {
    return all()
        .where((entry) => entry.saveToVaultByDefault)
        .toList(growable: false);
  }

  List<TruQuizRegistryEntry> profileCardEligible() {
    return all()
        .where((entry) => entry.supportsProfileCards)
        .toList(growable: false);
  }

  List<TruQuizRegistryEntry> matchingEligible() {
    return all()
        .where((entry) => entry.supportsMatching)
        .toList(growable: false);
  }

  Map<TruQuizCategory, int> countsByCategory() {
    return {
      for (final category in TruQuizCategory.values)
        category: byCategory(category).length,
    };
  }

  Map<TruQuizLedgerState, int> countsByLedgerState() {
    return {
      for (final state in TruQuizLedgerState.values)
        state: byLedgerState(state).length,
    };
  }

  TruQuizRegistryEntry? byId(String quizId) {
    for (final entry in _entries) {
      if (entry.quizId == quizId) return entry;
    }
    return null;
  }

  TruQuizRegistryEntry? featuredReadyEntry({
    required TruQuizCategory category,
    required TruQuizLauncherSurface surface,
  }) {
    final candidates = byCategory(category)
        .where(
          (entry) => entry.isReady && entry.launcherSurfaces.contains(surface),
        )
        .toList(growable: false);
    if (candidates.isEmpty) return null;
    return candidates.first;
  }

  List<TruQuizRegistryEntry> unlockedEntries({
    required Set<String> completedQuizIds,
  }) {
    return all().where((entry) {
      return entry.isUnlocked(
        completedQuizIds: completedQuizIds,
        completedQuizCount: completedQuizIds.length,
      );
    }).toList(growable: false);
  }

  String? launcherPathFor(TruQuizRegistryEntry entry) {
    if (!entry.isReady) return null;
    switch (entry.quizId) {
      case TruQuizEngine.friendshipEnergyMatchQuizId:
      case TruQuizEngine.socialStyleQuizId:
        return AppRoutes.microQuiz;
      default:
        return AppRoutes.quiz;
    }
  }

  static List<TruQuizRegistryEntry> _buildEntries() {
    final entries = <TruQuizRegistryEntry>[
      _readyMicroEntry(
        quizId: TruQuizEngine.friendshipEnergyMatchQuizId,
        title: 'Friendship Energy Match',
        category: TruQuizCategory.social,
        ledgerState: TruQuizLedgerState.recovery,
        subcategory: 'friendship',
        mode: TruQuizMode.social,
        orderIndex: 100,
        subtitle:
            'Lightweight social-pattern tuning for friend suggestions and discovery.',
        blueprint: TruQuizEngine.friendshipEnergyMatchBlueprint,
        visibilityDefault: TruQuizVisibility.profileOptIn,
        visibilityOptions: const <TruQuizVisibility>{
          TruQuizVisibility.privateOnly,
          TruQuizVisibility.profileOptIn,
        },
        effects: const <TruQuizEffect>{
          TruQuizEffect.feedPersonalization,
          TruQuizEffect.friendshipSuggestions,
          TruQuizEffect.nicheCommunitySuggestions,
          TruQuizEffect.profileCard,
          TruQuizEffect.savedVault,
        },
        launcherSurfaces: const <TruQuizLauncherSurface>{
          TruQuizLauncherSurface.quizLibrary,
          TruQuizLauncherSurface.homeAura,
          TruQuizLauncherSurface.settings,
          TruQuizLauncherSurface.profileGrowth,
          TruQuizLauncherSurface.profileCompatibility,
        },
        isCore: true,
        isOptional: true,
        isCanon: true,
        saveToVaultByDefault: true,
        supportsProfileCards: true,
        supportsMatching: false,
        unlockTier: TruQuizUnlockTier.open,
        startsUnlocked: true,
        unlockAfterQuizIds: const <String>[],
        minimumCompletedQuizzes: 0,
        estimatedMinutes: 3,
        tags: const <String>['friendship', 'aura', 'social energy'],
      ),
      _readyMicroEntry(
        quizId: TruQuizEngine.socialStyleQuizId,
        title: 'Social Style',
        category: TruQuizCategory.social,
        ledgerState: TruQuizLedgerState.recovery,
        subcategory: 'social-energy',
        mode: TruQuizMode.social,
        orderIndex: 110,
        subtitle:
            'Social pacing and presence signals for discovery and friends.',
        blueprint: TruQuizEngine.socialStyleBlueprint,
        visibilityDefault: TruQuizVisibility.profileOptIn,
        visibilityOptions: const <TruQuizVisibility>{
          TruQuizVisibility.privateOnly,
          TruQuizVisibility.profileOptIn,
        },
        effects: const <TruQuizEffect>{
          TruQuizEffect.feedPersonalization,
          TruQuizEffect.friendshipSuggestions,
          TruQuizEffect.nicheCommunitySuggestions,
          TruQuizEffect.profileCard,
          TruQuizEffect.savedVault,
        },
        launcherSurfaces: const <TruQuizLauncherSurface>{
          TruQuizLauncherSurface.quizLibrary,
          TruQuizLauncherSurface.homeAura,
          TruQuizLauncherSurface.settings,
          TruQuizLauncherSurface.profileGrowth,
        },
        isCore: true,
        isOptional: true,
        isCanon: true,
        saveToVaultByDefault: true,
        supportsProfileCards: true,
        supportsMatching: false,
        unlockTier: TruQuizUnlockTier.progressive,
        startsUnlocked: false,
        unlockAfterQuizIds: const <String>[
          TruQuizEngine.friendshipEnergyMatchQuizId,
        ],
        minimumCompletedQuizzes: 1,
        estimatedMinutes: 3,
        tags: const <String>['social', 'energy', 'aura'],
      ),
      _readyLongformEntry(
        quizId: TruQuizEngine.compatibilityBlueprint.quizId,
        title: 'Compatibility Layers',
        category: TruQuizCategory.advanced,
        ledgerState: TruQuizLedgerState.recovery,
        subcategory: 'compatibility',
        mode: TruQuizMode.advanced,
        orderIndex: 400,
        subtitle:
            'Deeper layered compatibility used for matching and advanced profile expansion.',
        blueprint: TruQuizEngine.compatibilityBlueprint,
        visibilityDefault: TruQuizVisibility.matchingOnly,
        visibilityOptions: const <TruQuizVisibility>{
          TruQuizVisibility.privateOnly,
          TruQuizVisibility.profileOptIn,
          TruQuizVisibility.matchingOnly,
        },
        effects: const <TruQuizEffect>{
          TruQuizEffect.feedPersonalization,
          TruQuizEffect.sparkDatingCompatibility,
          TruQuizEffect.friendshipSuggestions,
          TruQuizEffect.relationshipReadiness,
          TruQuizEffect.profileCard,
          TruQuizEffect.savedVault,
          TruQuizEffect.truJourney,
        },
        launcherSurfaces: const <TruQuizLauncherSurface>{
          TruQuizLauncherSurface.quizLibrary,
          TruQuizLauncherSurface.settings,
          TruQuizLauncherSurface.profileCompatibility,
          TruQuizLauncherSurface.matchingDeck,
        },
        isCore: true,
        isOptional: true,
        isCanon: true,
        saveToVaultByDefault: true,
        supportsProfileCards: true,
        supportsMatching: true,
        unlockTier: TruQuizUnlockTier.deepening,
        startsUnlocked: false,
        unlockAfterQuizIds: const <String>[
          TruQuizEngine.friendshipEnergyMatchQuizId,
        ],
        minimumCompletedQuizzes: 1,
        estimatedMinutes: 5,
        tags: const <String>['compatibility', 'advanced', 'matching'],
      ),
    ];

    entries.addAll(
      _plannedEntriesForCategory(
        category: TruQuizCategory.onboarding,
        ledgerState: TruQuizLedgerState.expansion,
        mode: TruQuizMode.onboarding,
        startOrder: 10,
        visibilityDefault: TruQuizVisibility.privateOnly,
        visibilityOptions: const <TruQuizVisibility>{
          TruQuizVisibility.privateOnly,
        },
        effects: const <TruQuizEffect>{
          TruQuizEffect.feedPersonalization,
          TruQuizEffect.savedVault,
        },
        launcherSurfaces: const <TruQuizLauncherSurface>{
          TruQuizLauncherSurface.onboardingFlow,
          TruQuizLauncherSurface.quizLibrary,
          TruQuizLauncherSurface.settings,
        },
        specs: const <_PlannedQuizSpec>[
          _PlannedQuizSpec(
            title: 'Intent Seed',
            subcategory: 'entry',
            subtitle: 'Fast intent capture for entry onboarding.',
            isCore: true,
            tags: <String>['entry', 'intent'],
          ),
          _PlannedQuizSpec(
            title: 'Mood Compass',
            subcategory: 'entry',
            subtitle: 'Calibrates starting tone, energy, and emotional pacing.',
            isCore: true,
            tags: <String>['mood', 'entry'],
          ),
          _PlannedQuizSpec(
            title: 'How Do You Want To Be Met?',
            subcategory: 'entry',
            subtitle: 'A quick read on first-contact style and early comfort.',
            isCore: true,
            tags: <String>['entry', 'comfort'],
          ),
          _PlannedQuizSpec(
            title: 'Conversation Comfort Meter',
            subcategory: 'entry',
            subtitle:
                'Sets preferred pacing for prompts, DMs, and warm starts.',
            tags: <String>['entry', 'conversation'],
          ),
          _PlannedQuizSpec(
            title: 'Soft Launch Personality Read',
            subcategory: 'entry',
            subtitle:
                'Shapes first-launch recommendations without heavy setup.',
            tags: <String>['entry', 'soft launch'],
          ),
          _PlannedQuizSpec(
            title: 'Interest Energy Starter',
            subcategory: 'entry',
            subtitle: 'Uses early interests to weight communities and people.',
            tags: <String>['entry', 'interests'],
          ),
          _PlannedQuizSpec(
            title: 'Social Battery Check-In',
            subcategory: 'entry',
            subtitle: 'Helps the app understand how open or guarded you feel.',
            tags: <String>['entry', 'social battery'],
          ),
          _PlannedQuizSpec(
            title: 'First Week Discovery Tuner',
            subcategory: 'entry',
            subtitle: 'Refines onboarding after a few sessions of real use.',
            tags: <String>['entry', 'discovery'],
          ),
        ],
      ),
    );

    entries.addAll(
      _plannedEntriesForCategory(
        category: TruQuizCategory.social,
        ledgerState: TruQuizLedgerState.expansion,
        mode: TruQuizMode.social,
        startOrder: 120,
        visibilityDefault: TruQuizVisibility.profileOptIn,
        visibilityOptions: const <TruQuizVisibility>{
          TruQuizVisibility.privateOnly,
          TruQuizVisibility.profileOptIn,
        },
        effects: const <TruQuizEffect>{
          TruQuizEffect.feedPersonalization,
          TruQuizEffect.friendshipSuggestions,
          TruQuizEffect.nicheCommunitySuggestions,
          TruQuizEffect.profileCard,
          TruQuizEffect.savedVault,
        },
        launcherSurfaces: const <TruQuizLauncherSurface>{
          TruQuizLauncherSurface.quizLibrary,
          TruQuizLauncherSurface.homeAura,
          TruQuizLauncherSurface.settings,
          TruQuizLauncherSurface.profileGrowth,
        },
        specs: const <_PlannedQuizSpec>[
          _PlannedQuizSpec(
            title: 'What Kind Of Friend Are You In A Crisis?',
            subcategory: 'friendship',
            subtitle: 'Maps your support style and friendship reflexes.',
            tags: <String>['friendship', 'support'],
          ),
          _PlannedQuizSpec(
            title: 'What Type Of Community Actually Fits Me?',
            subcategory: 'community',
            subtitle: 'Finds the social spaces you settle into most naturally.',
            tags: <String>['community', 'friendship'],
          ),
          _PlannedQuizSpec(
            title: 'How Social Am I Really?',
            subcategory: 'social-energy',
            subtitle:
                'Separates performative openness from actual social capacity.',
            tags: <String>['social', 'energy'],
          ),
          _PlannedQuizSpec(
            title: 'The Way I Let People In',
            subcategory: 'friendship',
            subtitle: 'Looks at trust, pace, and social access.',
            tags: <String>['trust', 'friendship'],
          ),
          _PlannedQuizSpec(
            title: 'Do I Need Deep Friends Or Fun Friends Right Now?',
            subcategory: 'friendship',
            subtitle: 'Weights discovery toward depth, play, or a mix.',
            tags: <String>['friendship', 'discovery'],
          ),
          _PlannedQuizSpec(
            title: 'What Type Of Social Energy Attracts Me?',
            subcategory: 'social-energy',
            subtitle: 'Finds the presence and rhythm you want around you.',
            tags: <String>['attraction', 'social'],
          ),
          _PlannedQuizSpec(
            title: 'My Posting Personality',
            subcategory: 'expression',
            subtitle: 'Tunes content prompts and feed expression surfaces.',
            tags: <String>['posting', 'expression'],
          ),
          _PlannedQuizSpec(
            title: 'Do I Need A Safe Circle Or A Bigger World?',
            subcategory: 'community',
            subtitle: 'Balances intimacy with broader discovery.',
            tags: <String>['community', 'safety'],
          ),
          _PlannedQuizSpec(
            title: 'What Kind Of Friendship Pace Feels Safe?',
            subcategory: 'friendship',
            subtitle: 'Understands how quickly closeness should build.',
            tags: <String>['friendship', 'pace'],
          ),
          _PlannedQuizSpec(
            title: 'The Group Chat Role I Always Become',
            subcategory: 'friendship',
            subtitle: 'Reads your natural role inside social clusters.',
            tags: <String>['group chat', 'friendship'],
          ),
          _PlannedQuizSpec(
            title: 'My Social Boundaries Blueprint',
            subcategory: 'boundaries',
            subtitle: 'Sets healthier discovery and interaction expectations.',
            tags: <String>['boundaries', 'social'],
          ),
          _PlannedQuizSpec(
            title: 'Who Do I Actually Click With As Friends?',
            subcategory: 'friendship',
            subtitle: 'Clarifies platonic chemistry across energy and values.',
            tags: <String>['friendship', 'chemistry'],
          ),
        ],
      ),
    );

    entries.addAll(
      _plannedEntriesForCategory(
        category: TruQuizCategory.spark,
        ledgerState: TruQuizLedgerState.expansion,
        mode: TruQuizMode.spark,
        startOrder: 200,
        visibilityDefault: TruQuizVisibility.matchingOnly,
        visibilityOptions: const <TruQuizVisibility>{
          TruQuizVisibility.privateOnly,
          TruQuizVisibility.profileOptIn,
          TruQuizVisibility.matchingOnly,
        },
        effects: const <TruQuizEffect>{
          TruQuizEffect.sparkDatingCompatibility,
          TruQuizEffect.attractionOverlays,
          TruQuizEffect.relationshipReadiness,
          TruQuizEffect.profileCard,
          TruQuizEffect.savedVault,
        },
        launcherSurfaces: const <TruQuizLauncherSurface>{
          TruQuizLauncherSurface.quizLibrary,
          TruQuizLauncherSurface.homeSpark,
          TruQuizLauncherSurface.settings,
          TruQuizLauncherSurface.profileCompatibility,
          TruQuizLauncherSurface.matchingDeck,
        },
        specs: const <_PlannedQuizSpec>[
          _PlannedQuizSpec(
            title: 'My Attraction Code: Soul, Body, and Mind Edition',
            subcategory: 'attraction',
            subtitle:
                'Canonical attraction mapping across emotional, physical, and intellectual pull.',
            ledgerState: TruQuizLedgerState.confirmed,
            isCore: true,
            isCanon: true,
            supportsMatching: true,
            tags: <String>['canon', 'attraction', 'spark'],
          ),
          _PlannedQuizSpec(
            title: 'If Fine Was a Person – Your Main Character Attraction Code',
            subcategory: 'attraction',
            subtitle:
                'Canonical Spark quiz for aesthetic magnetism, charisma, and visible chemistry.',
            ledgerState: TruQuizLedgerState.confirmed,
            isCore: true,
            isCanon: true,
            supportsMatching: true,
            tags: <String>['canon', 'attraction', 'aesthetic'],
          ),
          _PlannedQuizSpec(
            title: 'What’s My Ideal Love Language Profile?',
            subcategory: 'relationship',
            subtitle:
                'Canonical relationship quiz for how care should actually feel.',
            ledgerState: TruQuizLedgerState.confirmed,
            isCore: true,
            isCanon: true,
            supportsMatching: true,
            tags: <String>['canon', 'love language', 'relationship'],
          ),
          _PlannedQuizSpec(
            title: 'The Type Of Chemistry I Fall For First',
            subcategory: 'chemistry',
            subtitle: 'Maps what hooks your attention before logic catches up.',
            supportsMatching: true,
            tags: <String>['chemistry', 'spark'],
          ),
          _PlannedQuizSpec(
            title: 'What Makes Me Catch Feelings?',
            subcategory: 'chemistry',
            subtitle: 'Reads the emotional conditions that open your heart.',
            supportsMatching: true,
            tags: <String>['feelings', 'spark'],
          ),
          _PlannedQuizSpec(
            title: 'What Kind Of Flirting Actually Works On Me?',
            subcategory: 'flirting',
            subtitle: 'Separates cringe from genuine attraction cues.',
            supportsMatching: true,
            tags: <String>['flirting', 'spark'],
          ),
          _PlannedQuizSpec(
            title: 'What Type Of Energy Feels Irresistible To Me?',
            subcategory: 'attraction',
            subtitle: 'Understands the presence, style, and rhythm you crave.',
            supportsMatching: true,
            tags: <String>['attraction', 'energy'],
          ),
          _PlannedQuizSpec(
            title: 'My Romantic Green Flags',
            subcategory: 'relationship',
            subtitle:
                'Highlights the signals that make you trust romantic potential.',
            supportsMatching: true,
            tags: <String>['green flags', 'relationship'],
          ),
          _PlannedQuizSpec(
            title: 'My Romantic Red Flag Sensitivity',
            subcategory: 'relationship',
            subtitle: 'Maps what immediately turns you off or slows you down.',
            supportsMatching: true,
            tags: <String>['red flags', 'relationship'],
          ),
          _PlannedQuizSpec(
            title: 'The Way I Want To Be Pursued',
            subcategory: 'dating-style',
            subtitle: 'Tunes Spark for pace, effort, and directness.',
            supportsMatching: true,
            tags: <String>['dating style', 'spark'],
          ),
          _PlannedQuizSpec(
            title: 'What Type Of Dates Make Me Open Up?',
            subcategory: 'dating-style',
            subtitle:
                'Finds which romantic contexts actually create connection.',
            supportsMatching: true,
            tags: <String>['dating', 'connection'],
          ),
          _PlannedQuizSpec(
            title: 'My Emotional Attraction Style',
            subcategory: 'attraction',
            subtitle: 'Explores the emotional frequency that feels magnetic.',
            supportsMatching: true,
            tags: <String>['emotional attraction', 'spark'],
          ),
          _PlannedQuizSpec(
            title: 'My Physical Attraction Style',
            subcategory: 'attraction',
            subtitle: 'Examines embodiment, sensuality, and visible pull.',
            supportsMatching: true,
            tags: <String>['physical attraction', 'spark'],
          ),
          _PlannedQuizSpec(
            title: 'My Intellectual Attraction Style',
            subcategory: 'attraction',
            subtitle: 'Reads how mental chemistry and curiosity build desire.',
            supportsMatching: true,
            tags: <String>['intellectual attraction', 'spark'],
          ),
          _PlannedQuizSpec(
            title: 'The Lovers To Friends Ratio I Actually Need',
            subcategory: 'relationship',
            subtitle: 'Balances romance, play, and emotional partnership.',
            supportsMatching: true,
            tags: <String>['relationship', 'friendship'],
          ),
          _PlannedQuizSpec(
            title: 'How Fast Do I Want Romance To Move?',
            subcategory: 'dating-style',
            subtitle: 'Shapes Spark pacing and relationship tempo.',
            supportsMatching: true,
            tags: <String>['pace', 'dating'],
          ),
          _PlannedQuizSpec(
            title: 'What Makes Me Feel Chosen?',
            subcategory: 'relationship',
            subtitle: 'Finds the gestures and consistency that create safety.',
            supportsMatching: true,
            tags: <String>['chosen', 'relationship'],
          ),
          _PlannedQuizSpec(
            title: 'What Type Of Compliments Actually Land For Me?',
            subcategory: 'flirting',
            subtitle: 'Improves chemistry prompts and flirty compatibility.',
            supportsMatching: true,
            tags: <String>['compliments', 'spark'],
          ),
          _PlannedQuizSpec(
            title: 'The Kind Of Beauty I Notice First',
            subcategory: 'attraction',
            subtitle: 'Maps aesthetic attention and visible attraction cues.',
            supportsMatching: true,
            tags: <String>['beauty', 'aesthetic'],
          ),
          _PlannedQuizSpec(
            title: 'My Long-Term Compatibility Instinct',
            subcategory: 'relationship',
            subtitle:
                'Reads what signals durability instead of just intensity.',
            supportsMatching: true,
            tags: <String>['long-term', 'compatibility'],
          ),
          _PlannedQuizSpec(
            title: 'What Kind Of Passion Feels Safe To Me?',
            subcategory: 'chemistry',
            subtitle: 'Understands how intensity and safety can coexist.',
            supportsMatching: true,
            tags: <String>['passion', 'safety'],
          ),
          _PlannedQuizSpec(
            title: 'The Lovers Arc I Keep Repeating',
            subcategory: 'relationship',
            subtitle: 'Tracks repeated romantic trajectories and pacing loops.',
            supportsMatching: true,
            tags: <String>['patterns', 'relationship'],
          ),
          _PlannedQuizSpec(
            title: 'How Do I Know I’m Actually Into Someone?',
            subcategory: 'chemistry',
            subtitle:
                'Separates attraction, fascination, and emotional compatibility.',
            supportsMatching: true,
            tags: <String>['attraction', 'clarity'],
          ),
          _PlannedQuizSpec(
            title: 'My Commitment Temperature',
            subcategory: 'relationship',
            subtitle:
                'Reads readiness for exclusivity, consistency, and emotional investment.',
            supportsMatching: true,
            tags: <String>['commitment', 'spark'],
          ),
          _PlannedQuizSpec(
            title: 'What Makes Me Feel Desired In A Healthy Way?',
            subcategory: 'relationship',
            subtitle: 'Looks at desire, reassurance, and emotional steadiness.',
            supportsMatching: true,
            tags: <String>['desire', 'healthy love'],
          ),
          _PlannedQuizSpec(
            title: 'The Kind Of Romance I Romanticize',
            subcategory: 'dating-style',
            subtitle: 'Maps fantasy versus actual fit inside attraction.',
            supportsMatching: true,
            tags: <String>['fantasy', 'dating'],
          ),
          _PlannedQuizSpec(
            title: 'Would I Rather Be Seen, Protected, Or Pursued?',
            subcategory: 'relationship',
            subtitle:
                'Identifies your strongest emotional need inside romance.',
            supportsMatching: true,
            tags: <String>['needs', 'relationship'],
          ),
          _PlannedQuizSpec(
            title: 'What Type Of Partner Energy Grounds Me?',
            subcategory: 'relationship',
            subtitle: 'Tunes matching toward steadiness, depth, or fire.',
            supportsMatching: true,
            tags: <String>['partner energy', 'grounding'],
          ),
          _PlannedQuizSpec(
            title: 'My Slow Burn Vs Instant Spark Ratio',
            subcategory: 'chemistry',
            subtitle: 'Reads the pace at which attraction becomes attachment.',
            supportsMatching: true,
            tags: <String>['slow burn', 'spark'],
          ),
          _PlannedQuizSpec(
            title: 'The Type Of Romantic Attention I Trust',
            subcategory: 'relationship',
            subtitle: 'Matches attention style with emotional credibility.',
            supportsMatching: true,
            tags: <String>['attention', 'trust'],
          ),
          _PlannedQuizSpec(
            title: 'My Main Character Date Night Code',
            subcategory: 'dating-style',
            subtitle: 'Reads the kind of romance you feel instantly alive in.',
            supportsMatching: true,
            tags: <String>['main character', 'dating'],
          ),
        ],
      ),
    );

    entries.addAll(
      _plannedEntriesForCategory(
        category: TruQuizCategory.healing,
        ledgerState: TruQuizLedgerState.confirmed,
        mode: TruQuizMode.healing,
        startOrder: 300,
        visibilityDefault: TruQuizVisibility.privateOnly,
        visibilityOptions: const <TruQuizVisibility>{
          TruQuizVisibility.privateOnly,
          TruQuizVisibility.profileOptIn,
        },
        effects: const <TruQuizEffect>{
          TruQuizEffect.healingArchive,
          TruQuizEffect.truJourney,
          TruQuizEffect.savedVault,
        },
        launcherSurfaces: const <TruQuizLauncherSurface>{
          TruQuizLauncherSurface.quizLibrary,
          TruQuizLauncherSurface.settings,
          TruQuizLauncherSurface.profileCompatibility,
          TruQuizLauncherSurface.healingVault,
        },
        specs: const <_PlannedQuizSpec>[
          _PlannedQuizSpec(
            quizId: DeepQuizArchiveService.whyDidYouStaySoLongQuizId,
            title: 'Why Did You Stay So Long?',
            subcategory: 'archive',
            subtitle:
                'Canonical healing archive about attachment and endurance.',
            ledgerState: TruQuizLedgerState.confirmed,
            isCore: true,
            isCanon: true,
            tags: <String>['canon', 'healing', 'archive'],
          ),
          _PlannedQuizSpec(
            quizId: DeepQuizArchiveService.relationshipFlawsQuizId,
            title: 'What Are My Relationship Flaws?',
            subcategory: 'archive',
            subtitle:
                'Canonical reflection on recurring friction, blind spots, and repair gaps.',
            ledgerState: TruQuizLedgerState.confirmed,
            isCanon: true,
            tags: <String>['canon', 'healing', 'reflection'],
          ),
          _PlannedQuizSpec(
            quizId: DeepQuizArchiveService.amIReadyToBeLovedQuizId,
            title: 'Am I Ready to Be Loved the Way I Deserve?',
            subcategory: 'readiness',
            subtitle:
                'Canonical readiness read on openness, reciprocity, and emotional safety.',
            ledgerState: TruQuizLedgerState.confirmed,
            isCanon: true,
            tags: <String>['canon', 'readiness', 'healing'],
          ),
          _PlannedQuizSpec(
            title: 'How Did I Learn To Love?',
            subcategory: 'archive',
            subtitle: 'Explores the emotional scripts that shaped intimacy.',
            tags: <String>['healing', 'attachment'],
          ),
          _PlannedQuizSpec(
            title: 'What Do I Confuse With Love?',
            subcategory: 'archive',
            subtitle: 'Separates longing, survival, fantasy, and actual care.',
            tags: <String>['healing', 'love'],
          ),
          _PlannedQuizSpec(
            title: 'My Attachment Wound Pattern',
            subcategory: 'archive',
            subtitle: 'Maps recurring pain loops that show up in connection.',
            tags: <String>['attachment', 'healing'],
          ),
          _PlannedQuizSpec(
            title: 'The Boundary I Keep Betraying',
            subcategory: 'boundaries',
            subtitle: 'Tracks the limit you know but struggle to protect.',
            tags: <String>['boundaries', 'healing'],
          ),
          _PlannedQuizSpec(
            title: 'Why Do I Go Numb When I’m Hurt?',
            subcategory: 'repair',
            subtitle: 'Reads shutdown, overwhelm, and emotional distance.',
            tags: <String>['repair', 'healing'],
          ),
          _PlannedQuizSpec(
            title: 'What Does Safety Actually Feel Like In My Body?',
            subcategory: 'repair',
            subtitle: 'Translates safety from theory into lived signals.',
            tags: <String>['safety', 'body'],
          ),
          _PlannedQuizSpec(
            title: 'My Forgiveness Pattern',
            subcategory: 'repair',
            subtitle: 'Distinguishes grace, avoidance, and self-abandonment.',
            tags: <String>['forgiveness', 'healing'],
          ),
          _PlannedQuizSpec(
            title: 'The Story I Tell Myself After Rejection',
            subcategory: 'archive',
            subtitle: 'Finds the inner narratives that reopen old wounds.',
            tags: <String>['rejection', 'healing'],
          ),
          _PlannedQuizSpec(
            title: 'How Do I Protect Myself From Being Seen?',
            subcategory: 'repair',
            subtitle: 'Maps avoidance, armor, and emotional visibility.',
            tags: <String>['visibility', 'healing'],
          ),
        ],
      ),
    );

    entries.addAll(
      _plannedEntriesForCategory(
        category: TruQuizCategory.identity,
        ledgerState: TruQuizLedgerState.confirmed,
        mode: TruQuizMode.identity,
        startOrder: 500,
        visibilityDefault: TruQuizVisibility.profileOptIn,
        visibilityOptions: const <TruQuizVisibility>{
          TruQuizVisibility.privateOnly,
          TruQuizVisibility.profileOptIn,
        },
        effects: const <TruQuizEffect>{
          TruQuizEffect.identityReflection,
          TruQuizEffect.emotionalPatterning,
          TruQuizEffect.profileCard,
          TruQuizEffect.savedVault,
        },
        launcherSurfaces: const <TruQuizLauncherSurface>{
          TruQuizLauncherSurface.quizLibrary,
          TruQuizLauncherSurface.settings,
          TruQuizLauncherSurface.profileGrowth,
          TruQuizLauncherSurface.profileCompatibility,
        },
        specs: const <_PlannedQuizSpec>[
          _PlannedQuizSpec(
            quizId: DeepQuizArchiveService.emotionalTypeQuizId,
            title: 'What’s My Emotional Type?',
            subcategory: 'emotional-identity',
            subtitle:
                'Canonical emotional identity read for needs, rhythm, and repair language.',
            ledgerState: TruQuizLedgerState.confirmed,
            isCore: true,
            isCanon: true,
            tags: <String>['canon', 'identity', 'emotional type'],
          ),
          _PlannedQuizSpec(
            title: 'What Kind Of Softness Do I Actually Have?',
            subcategory: 'emotional-identity',
            subtitle: 'Maps tenderness, boundaries, and inner sensitivity.',
            tags: <String>['identity', 'softness'],
          ),
          _PlannedQuizSpec(
            title: 'My Emotional Processing Style',
            subcategory: 'emotional-identity',
            subtitle: 'Understands how you metabolize feelings and conflict.',
            tags: <String>['identity', 'processing'],
          ),
          _PlannedQuizSpec(
            title: 'The Version Of Me People Meet First',
            subcategory: 'self-expression',
            subtitle: 'Reads your outer layer versus your inner reality.',
            tags: <String>['identity', 'expression'],
          ),
          _PlannedQuizSpec(
            title: 'What Makes Me Feel Like Myself?',
            subcategory: 'self-expression',
            subtitle: 'Clarifies the environments and dynamics that feel true.',
            tags: <String>['identity', 'self'],
          ),
          _PlannedQuizSpec(
            title: 'My Inner Child Social Pattern',
            subcategory: 'emotional-identity',
            subtitle:
                'Looks at old adaptation styles still active in connection.',
            tags: <String>['identity', 'inner child'],
          ),
          _PlannedQuizSpec(
            title: 'Do I Feel More Like Fire, Water, Air, Or Earth In Love?',
            subcategory: 'self-expression',
            subtitle: 'Turns emotional style into a simple energetic language.',
            tags: <String>['identity', 'elements'],
          ),
          _PlannedQuizSpec(
            title: 'My Conflict Identity',
            subcategory: 'emotional-identity',
            subtitle: 'Maps who you become under pressure and friction.',
            tags: <String>['identity', 'conflict'],
          ),
          _PlannedQuizSpec(
            title: 'The Need I Hide Best',
            subcategory: 'emotional-identity',
            subtitle: 'Finds the emotional request you rarely say out loud.',
            tags: <String>['identity', 'needs'],
          ),
        ],
      ),
    );

    entries.addAll(
      _plannedEntriesForCategory(
        category: TruQuizCategory.advanced,
        ledgerState: TruQuizLedgerState.expansion,
        mode: TruQuizMode.advanced,
        startOrder: 410,
        visibilityDefault: TruQuizVisibility.matchingOnly,
        visibilityOptions: const <TruQuizVisibility>{
          TruQuizVisibility.privateOnly,
          TruQuizVisibility.profileOptIn,
          TruQuizVisibility.matchingOnly,
        },
        effects: const <TruQuizEffect>{
          TruQuizEffect.sparkDatingCompatibility,
          TruQuizEffect.friendshipSuggestions,
          TruQuizEffect.truJourney,
          TruQuizEffect.profileCard,
          TruQuizEffect.savedVault,
        },
        launcherSurfaces: const <TruQuizLauncherSurface>{
          TruQuizLauncherSurface.quizLibrary,
          TruQuizLauncherSurface.settings,
          TruQuizLauncherSurface.profileCompatibility,
          TruQuizLauncherSurface.matchingDeck,
        },
        specs: const <_PlannedQuizSpec>[
          _PlannedQuizSpec(
            title: 'Advanced Compatibility Layers II',
            subcategory: 'compatibility',
            subtitle: 'Expands on lifestyle, repair, and emotional pacing.',
            supportsMatching: true,
            tags: <String>['advanced', 'compatibility'],
          ),
          _PlannedQuizSpec(
            title: 'Relationship Longevity Signals',
            subcategory: 'compatibility',
            subtitle: 'Weights steadiness, maintenance, and long-range fit.',
            supportsMatching: true,
            tags: <String>['advanced', 'longevity'],
          ),
          _PlannedQuizSpec(
            title: 'Emotional Reciprocity Matrix',
            subcategory: 'compatibility',
            subtitle: 'Reads give-and-receive balance in close relationships.',
            supportsMatching: true,
            tags: <String>['advanced', 'reciprocity'],
          ),
          _PlannedQuizSpec(
            title: 'Conflict Repair Compatibility',
            subcategory: 'compatibility',
            subtitle: 'Looks at apology, accountability, and repair fit.',
            supportsMatching: true,
            tags: <String>['advanced', 'repair'],
          ),
          _PlannedQuizSpec(
            title: 'Lifestyle Friction Forecast',
            subcategory: 'compatibility',
            subtitle: 'Forecasts rhythm mismatches before they become issues.',
            supportsMatching: true,
            tags: <String>['advanced', 'lifestyle'],
          ),
          _PlannedQuizSpec(
            title: 'Secure Attachment Compatibility Index',
            subcategory: 'compatibility',
            subtitle:
                'Measures how safety and steadiness align between people.',
            supportsMatching: true,
            tags: <String>['advanced', 'attachment'],
          ),
          _PlannedQuizSpec(
            title: 'Communication Repair Depth Read',
            subcategory: 'compatibility',
            subtitle:
                'Maps how well two people move through misunderstandings.',
            supportsMatching: true,
            tags: <String>['advanced', 'communication'],
          ),
          _PlannedQuizSpec(
            title: 'Value Alignment Decoder',
            subcategory: 'compatibility',
            subtitle:
                'Separates vibe compatibility from core value compatibility.',
            supportsMatching: true,
            tags: <String>['advanced', 'values'],
          ),
          _PlannedQuizSpec(
            title: 'Attachment Trigger Compatibility',
            subcategory: 'compatibility',
            subtitle:
                'Predicts how patterns may activate or soothe each other.',
            supportsMatching: true,
            tags: <String>['advanced', 'triggers'],
          ),
          _PlannedQuizSpec(
            title: 'Long-Term Ritual Fit',
            subcategory: 'compatibility',
            subtitle: 'Reads everyday rituals and future lifestyle alignment.',
            supportsMatching: true,
            tags: <String>['advanced', 'rituals'],
          ),
          _PlannedQuizSpec(
            title: 'Multi-Layer Attraction Vs Compatibility Decoder',
            subcategory: 'compatibility',
            subtitle: 'Separates chemistry heat from actual relational fit.',
            supportsMatching: true,
            tags: <String>['advanced', 'chemistry'],
          ),
        ],
      ),
    );

    return entries..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }
}

class _PlannedQuizSpec {
  final String? quizId;
  final String title;
  final String subcategory;
  final String subtitle;
  final TruQuizLedgerState? ledgerState;
  final bool isCore;
  final bool isCanon;
  final bool supportsMatching;
  final List<String> tags;

  const _PlannedQuizSpec({
    this.quizId,
    required this.title,
    required this.subcategory,
    required this.subtitle,
    this.ledgerState,
    this.isCore = false,
    this.isCanon = false,
    this.supportsMatching = false,
    this.tags = const <String>[],
  });
}

TruQuizRegistryEntry _readyMicroEntry({
  required String quizId,
  required String title,
  required TruQuizCategory category,
  required TruQuizLedgerState ledgerState,
  required String subcategory,
  required TruQuizMode mode,
  required int orderIndex,
  required String subtitle,
  required TruMicroQuizBlueprint blueprint,
  required TruQuizVisibility visibilityDefault,
  required Set<TruQuizVisibility> visibilityOptions,
  required Set<TruQuizEffect> effects,
  required Set<TruQuizLauncherSurface> launcherSurfaces,
  required bool isCore,
  required bool isOptional,
  required bool isCanon,
  required bool saveToVaultByDefault,
  required bool supportsProfileCards,
  required bool supportsMatching,
  required TruQuizUnlockTier unlockTier,
  required bool startsUnlocked,
  required List<String> unlockAfterQuizIds,
  required int minimumCompletedQuizzes,
  required int estimatedMinutes,
  required List<String> tags,
}) {
  return TruQuizRegistryEntry(
    quizId: quizId,
    title: title,
    category: category,
    ledgerState: ledgerState,
    subcategory: subcategory,
    mode: mode,
    questionSet: blueprint.questions
        .asMap()
        .entries
        .map(
          (entry) => TruQuizQuestionDefinition(
            id: '${quizId}_q${entry.key + 1}',
            prompt: entry.value.prompt,
            options: entry.value.options
                .asMap()
                .entries
                .map(
                  (option) => TruQuizAnswerOption(
                    id: '${quizId}_q${entry.key + 1}_o${option.key + 1}',
                    label: option.value.label,
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false),
    resultType: TruQuizResultType.archetype,
    visibilityDefault: visibilityDefault,
    visibilityOptions: visibilityOptions,
    effects: effects,
    launcherSurfaces: launcherSurfaces,
    isCore: isCore,
    isOptional: isOptional,
    isCanon: isCanon,
    saveToVaultByDefault: saveToVaultByDefault,
    supportsProfileCards: supportsProfileCards,
    supportsMatching: supportsMatching,
    unlockTier: unlockTier,
    startsUnlocked: startsUnlocked,
    unlockAfterQuizIds: unlockAfterQuizIds,
    minimumCompletedQuizzes: minimumCompletedQuizzes,
    orderIndex: orderIndex,
    estimatedMinutes: estimatedMinutes,
    tags: tags,
    subtitle: subtitle,
  );
}

TruQuizRegistryEntry _readyLongformEntry({
  required String quizId,
  required String title,
  required TruQuizCategory category,
  required TruQuizLedgerState ledgerState,
  required String subcategory,
  required TruQuizMode mode,
  required int orderIndex,
  required String subtitle,
  required TruQuizBlueprint blueprint,
  required TruQuizVisibility visibilityDefault,
  required Set<TruQuizVisibility> visibilityOptions,
  required Set<TruQuizEffect> effects,
  required Set<TruQuizLauncherSurface> launcherSurfaces,
  required bool isCore,
  required bool isOptional,
  required bool isCanon,
  required bool saveToVaultByDefault,
  required bool supportsProfileCards,
  required bool supportsMatching,
  required TruQuizUnlockTier unlockTier,
  required bool startsUnlocked,
  required List<String> unlockAfterQuizIds,
  required int minimumCompletedQuizzes,
  required int estimatedMinutes,
  required List<String> tags,
}) {
  return TruQuizRegistryEntry(
    quizId: quizId,
    title: title,
    category: category,
    ledgerState: ledgerState,
    subcategory: subcategory,
    mode: mode,
    questionSet: blueprint.questions
        .asMap()
        .entries
        .map(
          (entry) => TruQuizQuestionDefinition(
            id: '${quizId}_q${entry.key + 1}',
            prompt: entry.value.prompt,
            options: entry.value.options
                .asMap()
                .entries
                .map(
                  (option) => TruQuizAnswerOption(
                    id: '${quizId}_q${entry.key + 1}_o${option.key + 1}',
                    label: option.value.label,
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false),
    resultType: TruQuizResultType.compatibility,
    visibilityDefault: visibilityDefault,
    visibilityOptions: visibilityOptions,
    effects: effects,
    launcherSurfaces: launcherSurfaces,
    isCore: isCore,
    isOptional: isOptional,
    isCanon: isCanon,
    saveToVaultByDefault: saveToVaultByDefault,
    supportsProfileCards: supportsProfileCards,
    supportsMatching: supportsMatching,
    unlockTier: unlockTier,
    startsUnlocked: startsUnlocked,
    unlockAfterQuizIds: unlockAfterQuizIds,
    minimumCompletedQuizzes: minimumCompletedQuizzes,
    orderIndex: orderIndex,
    estimatedMinutes: estimatedMinutes,
    tags: tags,
    subtitle: subtitle,
  );
}

List<TruQuizRegistryEntry> _plannedEntriesForCategory({
  required TruQuizCategory category,
  required TruQuizLedgerState ledgerState,
  required TruQuizMode mode,
  required int startOrder,
  required TruQuizVisibility visibilityDefault,
  required Set<TruQuizVisibility> visibilityOptions,
  required Set<TruQuizEffect> effects,
  required Set<TruQuizLauncherSurface> launcherSurfaces,
  required List<_PlannedQuizSpec> specs,
}) {
  return specs.asMap().entries.map((entry) {
    final spec = entry.value;
    return TruQuizRegistryEntry(
      quizId: spec.quizId ?? _slugify(spec.title),
      title: spec.title,
      category: category,
      ledgerState: spec.ledgerState ?? ledgerState,
      subcategory: spec.subcategory,
      mode: mode,
      questionSet: const <TruQuizQuestionDefinition>[],
      resultType: switch (category) {
        TruQuizCategory.healing => TruQuizResultType.reflectiveInsights,
        TruQuizCategory.identity => TruQuizResultType.archetype,
        TruQuizCategory.spark => TruQuizResultType.attractionProfile,
        TruQuizCategory.advanced => TruQuizResultType.compatibility,
        _ => TruQuizResultType.traits,
      },
      visibilityDefault: visibilityDefault,
      visibilityOptions: visibilityOptions,
      effects: effects,
      launcherSurfaces: launcherSurfaces,
      isCore: spec.isCore,
      isOptional: true,
      isCanon: spec.isCanon,
      saveToVaultByDefault: true,
      supportsProfileCards:
          visibilityOptions.contains(TruQuizVisibility.profileOptIn),
      supportsMatching: spec.supportsMatching,
      unlockTier: category == TruQuizCategory.onboarding
          ? TruQuizUnlockTier.open
          : category == TruQuizCategory.healing ||
                  category == TruQuizCategory.advanced
              ? TruQuizUnlockTier.deepening
              : TruQuizUnlockTier.progressive,
      startsUnlocked: category == TruQuizCategory.onboarding,
      unlockAfterQuizIds: switch (category) {
        TruQuizCategory.healing => const <String>[
            DeepQuizArchiveService.whyDidYouStaySoLongQuizId,
          ],
        TruQuizCategory.advanced => const <String>[
            TruQuizEngine.compatibilityQuizId,
          ],
        TruQuizCategory.spark => const <String>[
            TruQuizEngine.friendshipEnergyMatchQuizId,
          ],
        TruQuizCategory.social => const <String>[],
        TruQuizCategory.identity => const <String>[
            DeepQuizArchiveService.emotionalTypeQuizId,
          ],
        TruQuizCategory.onboarding => const <String>[],
      },
      minimumCompletedQuizzes: switch (category) {
        TruQuizCategory.onboarding => 0,
        TruQuizCategory.social => 1,
        TruQuizCategory.spark => 1,
        TruQuizCategory.healing => 2,
        TruQuizCategory.identity => 1,
        TruQuizCategory.advanced => 2,
      },
      orderIndex: startOrder + entry.key,
      estimatedMinutes: category == TruQuizCategory.healing ? 8 : 5,
      tags: spec.tags,
      subtitle: spec.subtitle,
    );
  }).toList(growable: false);
}

String _slugify(String title) {
  final buffer = StringBuffer();
  var previousWasUnderscore = false;
  for (final codeUnit in title.toLowerCase().codeUnits) {
    final isAlphaNumeric = (codeUnit >= 97 && codeUnit <= 122) ||
        (codeUnit >= 48 && codeUnit <= 57);
    if (isAlphaNumeric) {
      buffer.writeCharCode(codeUnit);
      previousWasUnderscore = false;
      continue;
    }
    if (!previousWasUnderscore) {
      buffer.write('_');
      previousWasUnderscore = true;
    }
  }
  final normalized = buffer.toString().replaceAll(RegExp(r'^_+|_+$'), '');
  return normalized.isEmpty ? 'quiz' : normalized;
}
