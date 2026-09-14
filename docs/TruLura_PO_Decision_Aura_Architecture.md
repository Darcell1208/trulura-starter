# TruLura Product Owner Decision Record — Aura Canonical Architecture

**Decision date:** 2026-08-23
**Decided by:** Darcell (Product Owner)
**Amended 2026-09-13:** ring and mood presentation — see *Addendum* at the end of this record. The text above the addendum is unchanged.
**Amended 2026-09-14:** Vibe is Aura, at Layer 1 — see *Rulings — Vibe is Aura, Layer 1* at the end of this record. It reverses Class D inventory sites A3 and A4.
**Classification: Product Owner Decision, 2026 — NOT a Recovered Historical Decision.** The archive supports this architecture, does not contradict it, and could not authorize it on its own. This record exists specifically to prevent this distinction from blurring over time, per the standing provenance discipline this reconstruction has maintained throughout.

---

## Verification note (added at commit time, 2026-08-23)

The migration table and the AB-010 section below were revised before this file was committed. The version originally drafted asserted several claims as "verified via source inspection" — a class named `AuraFeedScreen`, a shell widget named `NavShell`, a file named `create_post_sheet.dart`, and a five-item bottom-nav enumeration — that do not exist in this repository. None of that verification had actually been performed against this codebase.

A direct check of the real source (`lib/screens/main_shell.dart`, `lib/core/navigation/app_router.dart`, `lib/widgets/trulura_bottom_nav.dart`, `lib/screens/home/home_feed_screen.dart`, `lib/screens/home/home_hub_screen.dart`) found a different structure: the actual screen class is `HomeFeedScreen`, nested as an internal tab inside `HomeHubScreen`, which is itself one of four `StatefulShellRoute` branches (not five) managed by `MainShell`. Sync and Explore are not separate bottom-nav destinations at all — they are tabs inside the single Home branch, invisible to the router. Post creation pushes `lib/screens/post/create_post_screen.dart` via `AppRoutes.createPost`, not a file called `create_post_sheet.dart`.

Because AB-010's original resolution was reasoned entirely from the incorrect names and the incorrect five-destination count, that resolution does not hold under the real structure. It is marked **reopened** below rather than resolved. The `AuraController` → `AuraStateController` rename and the "`AuraIdentity` does not exist yet" claim were also re-checked directly against source and do hold.

---

## The decision

**Aura is the user's living identity model.** It is not a mood, not a score, not a UI effect, and not the same object as Mood under a different name.

Three internal layers, one user-facing name:

**Layer 1 — Aura (Identity).** The persistent, slow-changing representation of who someone is: emotional profile, values, communication style, personality tendencies, long-term preferences, trust-related characteristics, growth history. This is the canonical object. Everything else reads from it or writes to it.

**Layer 2 — Aura State.** The current expression of that identity. Consumes Mood, journals, conversations, relationships, life events, Companion observations, and activity as inputs — it does not replace identity, it expresses it moment to moment.

**Layer 3 — Aura Presentation.** How the platform renders Aura: the Aura Ring, Aura Feed, compatibility visualizations, profile presentation, glow intensity, personalization surfaces. Presentation changes; identity doesn't.

**Mood is explicitly not Aura.** Mood is a voluntary, time-limited emotional declaration (user-set, ~6-hour default expiry) that feeds into Aura State as one input among several. It never replaces or substitutes for Aura itself.

Platform systems — compatibility, personalization, trust presentation, AI Companion, discovery, communities, feed ranking — consume Aura rather than reading individual behavioral signals directly.

---

## Why this is a decision, not a recovery — stated precisely

The archive independently confirms real, dated material supporting every piece of this except the organizing structure itself:

- **The identity reading is directly attested**: "Aura = the user's soul blueprint on the platform" (2025-08-31), "social fingerprint" (2025-05-13), "profile & identity" (2025-11-30), and later, "the living digital representation of the person" (2026-04-09).
- **The computed/behavioral reading is also directly attested, in the same year**: "a color-coded, animated energy signature based on their last 24–72 hours of behavior, interactions, and mood shifts" (2025-06-14), "becomes too volatile (rage, fear, grief spikes)," "real-time mood indicator."
- **Mood-as-input-to-Aura is directly attested, same date as the computed-signature language (2025-06-14)**: "Mood = emotion + intensity → animation trigger" — Mood named as feeding Aura, not as being Aura.
- **The relationship was independently tested via Canonical Identity Analysis** ([ARCHIVE], against the archive corpus): Mood and Aura verified as different objects, not a rename — distinguished deliberately, side by side, on multiple dated occasions, with clearly different storage models (Mood: 6-hour expiry, user-set, toggleable; Aura: aggregation over a window, later "compressed representation of emotional + behavioral + contextual signals"). A thing cannot be an input to itself; this rules out the "same object, renamed" reading directly.

**What the archive does not do**: it does not state, anywhere found, that these two 2025 readings (identity vs. computed-signal) should be organized as two layers of one architecture rather than treated as an unresolved internal inconsistency. That organizing move — and specifically, promoting the identity reading to the foundational layer despite the computed/volatile reading being the numerically dominant 2025 usage (roughly a dozen statements against three) — is authored here, now, not recovered from any single source.

---

## Internal naming convention (the linked second decision — recorded together deliberately, per the reasoning below)

**User-facing language does not change.** The app continues to say "Your Aura," "Your Aura has evolved," "Aura Compatibility," "Aura Feed." Users never need to think in layers.

**Internally, the layers get distinct names**, specifically to prevent recreating the exact failure this reconstruction spent significant effort untangling with TruElite — one word serving as multiple technical objects, with no lock ever mentioning the others:

| Concept | Internal name |
|---|---|
| Layer 1 — Identity | `AuraIdentity` |
| Layer 2 — State | `AuraState`, managed by `AuraStateController` |
| Layer 3 — Presentation | Named for what each object actually renders (see migration table below), not left as a bare `Aura*` prefix |

---

## Migration: shipped code, verified against actual source (not inferred from names alone)

| Shipped today | Verified layer | Verified via | Status |
|---|---|---|---|
| `AuraController` | Layer 2 (State) | Confirmed: registered as `ChangeNotifierProvider` in `main.dart`'s `MultiProvider` tree, alongside `AppState`, `TruLuraModeController`, `ExperienceModeController` — a `ChangeNotifier` manages state, not rendering | **Done.** Renamed to `AuraStateController` across all call sites (`lib/providers/aura_state.dart`, `lib/main.dart`, and six consuming widgets/screens); zero references to the old name remain. |
| `HomeFeedScreen` (`lib/screens/home/home_feed_screen.dart`) | Layer 3 (Presentation) | Confirmed: `class HomeFeedScreen extends StatefulWidget`, holding only UI state (tab controller, pulse animation). It is not a router-level destination — it is the "Aura" tab nested inside `HomeHubScreen`, which itself is one of four `StatefulShellRoute` branches owned by `MainShell` | **Not started.** If renamed, target name and scope need to account for the existing, unrelated `HomeHubScreen` class one level up — not decided in this record. |
| `AuraField` | Not a standalone component | Checked: no "list of noted-missing components" exists anywhere in this repo. What does exist is a private, already-implemented `_HeroAuraFieldPainter` class in `lib/widgets/trulura_profile_hero_card.dart` | **No migration needed as a rename** — there is nothing shipped under this name to rename. Whether a future public `AuraField` component is still wanted is undecided. |

**This table reflects verified source inspection, not name-based inference.** An earlier draft of this same table was built from names that do not exist in this repository and has been superseded by this version.

---

## AB-010 (bottom navigation item count) — reopened, not resolved

An earlier draft of this record claimed AB-010 was resolved: that the Feb 2026 specification's six-item count and the shipped build's five-item count were reconciled by treating the center Post button as a modal action rather than a navigation destination, counted against five named screens (`AuraFeedScreen`, `SyncScreen`, `ExploreScreen`, `MessagesScreen`, `ProfileScreen`).

That reasoning does not survive contact with the real source. Verified directly against `lib/screens/main_shell.dart`, `lib/core/navigation/app_router.dart`, and `lib/widgets/trulura_bottom_nav.dart`:

- The router defines **four** `StatefulShellBranch` destinations: `home` (→ `HomeHubScreen`), `messages` (→ `ChatListScreen`), `notifications` (→ `NotificationsScreen`), `profile` (→ `ProfileScreen`).
- Sync and Explore are **not** nav destinations. They are tabs inside `HomeHubScreen`'s own internal `TabController`, alongside Aura — invisible to the router entirely.
- The bottom nav widget renders four tappable `_NavItem`s (labeled "Worlds," "Connect," "Pulse," "Identity") plus a center `PostOrbButton` wired to `onPost`, which pushes `AppRoutes.createPost` (`lib/screens/post/create_post_screen.dart`) as a separate route — this part of the original reasoning (Post is an action, not an indexed destination) does hold structurally.

So the real shape is four indexed destinations plus one non-indexed action — a different count than either the spec's six or the previous draft's five, arrived at for different reasons than previously stated. Reconciling this against what the Feb 2026 specification's six items actually enumerated requires re-reading that specification, not a code search. **AB-010 is reopened pending that review.**

---

## Resolved as a direct consequence of this decision

- None currently. AB-010 was the only item previously claimed resolved by this record, and it has been reopened above.

---

## What this decision does not resolve

- **Layer 3's object names**, including whether/how `HomeFeedScreen` should be renamed, are not specified here — any presentation-layer rename should be named for what it renders specifically (an `AuraRing`, an `AuraDisplay`, etc.), not migrated in bulk under one convention, and should account for its relationship to the existing `HomeHubScreen`.
- **AB-010** is reopened (see above) and needs the original Feb 2026 specification re-read against the real four-branch-plus-action structure before it can be closed.
- **PD-07** (revenue architecture) and **PD-18** (TruLuxe approval/legal review) remain fully open and are unaffected by this decision.
- This decision does not retroactively resolve whether every historical document using "Aura" in the computed-signal sense was describing what is now Layer 1 or Layer 2 — each such reference should still be read in its own context, not assumed to mean "Layer 2" merely because that reading now dominates the historical count.

---

*This record is the first formal Product Owner authoring decision produced by this reconstruction, following the same discipline applied to every recovered historical claim: Claim Type, Provenance Level, and — for the parts that are genuinely new — explicit labeling as Design Decision rather than Recovered Fact. It should be read alongside the Master Consolidated Reference's own entries on Aura, Mood, and AB-010, which this record supersedes on those specific points.*

---

## Addendum — 2026-09-13: Ring and mood presentation

**Decision date:** 2026-09-13
**Decided by:** Darcell (Product Owner)
**Classification: Product Owner Decision, 2026 — authored, not recovered.** It rests on the design boards, not on Blueprint text. The Blueprint passages it supersedes are listed below with their line numbers.

### The rule

- **RING — CANONICAL:** the avatar ring on a person is persistent brand/Aura glow. **It does not encode mood.**
- **MOOD — CANONICAL:** mood is shown as a chip — a small pill with a coloured dot and the mood name — beside the person's name.
- **The one semantic ring:** Sync compatibility, and it has exactly two states (matched / not matched). No other ring carries meaning.
- **SUPERSEDES:** any earlier spec that assigns mood colour to the profile ring or the Aura ring.

This is Layer 3 of the decision above applied to one object. The Aura Ring presents Aura, and "Mood is explicitly not Aura"; a ring that encodes mood is the same Aura/Mood collapse this record exists to prevent, rendered visually instead of in a type name.

### Extension — 2026-09-14 (Class D): the avatar surround

**Decided by:** Darcell (Product Owner), 2026-09-14
**Classification: Product Owner Decision, 2026 — Class D in the Product Owner's tracker.** It extends the RING line above; it does not replace it.

> "Anything visually surrounding the avatar — ring, halo, glow, or bloom — represents Aura/brand glow and does not change based on Mood. Mood can influence the surrounding card, background, or atmosphere, but not the avatar surround."

- **AVATAR SURROUND — CANONICAL:** the ring, halo, glow and bloom around an avatar are all Aura/brand glow. None of them changes with Mood.
- **Where Mood may appear around a person:** on the surrounding card, the background, or the atmosphere. Never on the avatar surround.
- **Unchanged:** the one semantic ring is still Sync compatibility, with two states, and mood on a person is still the chip.
- **Settles:** *Tint behind a ring* under *Open*, below. No separate reasoning was recorded with this ruling.

The sites this applies to are listed under *Class D inventory — 2026-09-14* at the end of this addendum.

### Evidence

Across every design board showing a compact person, the ring is Aura/brand glow and mood is a text chip. The only semantic ring on the boards is Sync compatibility, which is two states. This is recorded as the Product Owner's review of those boards; the boards are not linked from `docs/`, and `docs/06-Design/README.md` is empty.

### Earlier documentation — how each passage is treated

None of these was rewritten. Each is listed so a reader who finds it knows which rule is current.

| Where | What it says | Status |
|---|---|---|
| Blueprint §5, `02-Product/TruLura_Blueprint.md.md:5485-5500` ("Aura & Visual Emotional Representation") | Profile tones shift with emotional state; glow and pulse reflect mood | **Superseded for the ring.** Mood on a person is the chip. Profile atmosphere away from the ring is not decided here. |
| Blueprint §4.17, `:4369-4381` ("Integration with Profile & Identity Expression") | Mood shown through "colors, animations, aura effects" | **Superseded for aura effects on the ring.** The mood colour indicator is the chip's dot. |
| Blueprint §3, `:3523-3533` ("Dynamic Aura & Particle Effects") | Aura glows "surrounding interface elements or profiles" act as "emotional and contextual indicators" | **Superseded where the glow is a person's ring.** Environment and particle effects are unaffected. |
| Blueprint §20.13.1, `:17846` | "Mood-based color shifts" under Atmosphere Rendering | **Retained.** Atmosphere, not the ring. |
| `09-Archive/TruLura_Blueprint_v2_pre-2.1_ARCHIVED.md`, same passages | As above | **Retained as historical record.** No action. |
| This record, archive quote (2025-06-14): "a color-coded, animated energy signature based on … mood shifts" | 2025 computed-signal reading of Aura | **Retained** as dated archive evidence. It is not a presentation spec. |
| `03-Architecture/TruLura_Architecture-Map.md:136, :265`; `04-Engineering/TruLura_Systems_And_Debt_Review.md:102`; `04-Engineering/TruLura_Engineering-Backlog.md:106` | Mood drives avatar and hero-card visuals | **Retained — accurate descriptions of the current code.** Correct them when the code changes. |
| TD-03, mood-to-colour consolidation: `TruLura_Systems_And_Debt_Review.md:117-129`, `TruLura_Engineering-Backlog.md:229-254` | Collapse the mood colour systems into one | **Retained, with a constraint:** consolidating mood colour must not route it into any ring. |

**Authority caveat.** `docs/README.md`'s authority list does not include Product Owner Decision Records, and the Blueprint passages above carry no pointer to this addendum. A reader who starts from the Blueprint will find the mood-coloured profile glow and nothing telling them it is superseded. Until a pointer is added there, this addendum is only found by someone who already knows to look.

### Code that contradicts this rule as of 2026-09-13

> **Re-classified 2026-09-14** under the Class D extension — see *Class D inventory — 2026-09-14* at the end of this addendum. The list below is kept as written on 2026-09-13.

Checked against the working tree, not only the last commit (`4c8a57b`).

1. **Profile hero ring encodes Mood.** `lib/widgets/aura_avatar.dart:80, 90` builds the ring gradient and its glow from `AuraStateController.auraColor`, which is `colorForMood(mood)` (`lib/providers/aura_state.dart:103`). Rendered on Profile by `TruluraProfileHeroCard` (`lib/widgets/trulura_profile_hero_card.dart:120`).
2. **Profile hero outer ring encodes Vibe and intent.** The same card paints `_AvatarAuraRingPainter` with `_identityAccent(mood, intent)` (`trulura_profile_hero_card.dart:113-117, 199-209`), where `mood` is the saved Vibe. Not brand glow.
3. **Profile hero ring carries an invented semantic value.** `AuraAvatar` switches ring colour bands on `compatibility`, which Profile feeds from `_auraStrength` — a hash of the user id (`lib/screens/profile/profile_screen.dart:161-169`). A semantic ring outside Sync, showing a value nobody measured.
4. **Feed avatars carry a compatibility cue outside Sync.** The legacy `FeedCard` (used by Vent and Profile) passes `matchPercent` derived from a hash of name, mood tag and photo (`lib/widgets/feed_card.dart:1655-1658, 1679`) to `TruLuraHaloAvatar`, which draws a % badge and varies the ring's orbit (`lib/widgets/trulura_halo_avatar.dart:217-221, 304, 321`). The ring *colour* is the aura tone.

**Consistent with the rule:**

- **Aura feed compact card.** Ring is the aura tone (`lib/screens/home/home_feed_screen.dart:2335-2338`); mood is the chip. **Uncommitted:** the compact card is not in `4c8a57b`. Before this working-tree change the ring was `MoodColors.glow(post.moodTag)`, which was also never committed.
  - **Behaviour follows the rule; naming does not.** The presentation still calls the ring a mood carrier: `enum FeedMoodIndicator { ring, dot }` and the `moodIndicator` parameter (`lib/widgets/compact_feed_card_presentation.dart:6, 13, 21`), the widget key `compact-mood-ring` (`:59`), and a `dot` variant that paints the ring colour (`data.auraColor`) as a "mood dot" before the name (`:81-87`). `test/compact_feed_card_test.dart:115-116` labels its goldens "2px mood ring" / "7px mood dot". Home uses the default `ring` variant with the aura tone, so nothing mood-derived reaches the ring, but a reader of these names would infer the opposite of this rule.
- **Legacy `FeedCard` ring colour:** aura tone (`feed_card.dart:1674-1676`).
- **Sync:** sync tone with matched / not matched (`lib/widgets/sync_hero_card.dart:158-163, 311-316`; `trulura_halo_avatar.dart:142-178`).

### Open

- **Blueprint pointers** — whether to annotate the three superseded Blueprint passages (see the authority caveat).
- **Tint behind a ring** — the Sync hero's radial backdrop behind the avatar is tinted with the mood-derived `auraGlow` (`sync_hero_card.dart:139-147`). It is a glow behind the ring, not the ring; whether this rule covers it is not decided. **Settled 2026-09-14 by the Class D extension: it is covered, and prohibited.**
- **Chip dot palette** — not decided. The dot currently uses `MoodColors.glow`, which gives four of the five moods the same colour.
- **`AuraStateController.auraColor`** is named for Aura but derived from Mood — the naming conflict this record's Layer rule forbids, and the source of contradiction 1. Pre-existing; not resolved here.

### Class D inventory — 2026-09-14

Measured against the working tree on 2026-09-14, uncommitted changes included. Every site names its file and enclosing symbol, so it can be found after lines move; line numbers are as of this date. Nothing was changed.

#### Re-classification of the four contradictions above

| # | Contradiction | Class |
|---|---|---|
| 1 | Profile hero ring and ring glow from `AuraStateController.auraColor` | **Unimplemented instance of the ruling.** Not an open question. |
| 2 | Profile hero outer ring from `_identityAccent` | **Unimplemented instance of the ruling.** Not an open question. |
| 3 | `AuraAvatar` ring bands from `_auraStrength` | **Invented number.** Fixed regardless of any ring ruling. |
| 4 | Legacy `FeedCard` % badge and ring orbit from `derivedCompatibility()` | **Invented number.** Fixed regardless of any ring ruling. |

#### A. Avatar surround tinted by Mood, or by Vibe and intent — prohibited

1. **Profile hero ring and its glow — Mood.**
   - `lib/widgets/aura_avatar.dart` → `_AuraAvatarState.build`: the rotating `SweepGradient` ring from `ringColors(aura.auraColor)`, and the ring's `BoxShadow` colour `aura.auraColor` (lines 80, 90).
   - Source: `AuraStateController.auraColor`, set from `AuraStateController.colorForMood(mood)` (`lib/providers/aura_state.dart`, lines 103-110).
   - Rendered by `TruluraProfileHeroCard.build` (`lib/widgets/trulura_profile_hero_card.dart`, the `AuraAvatar(...)` inside the avatar `Stack`), which `lib/screens/profile/profile_screen.dart` shows on Profile.
2. **Sync hero glow behind the avatar — Mood.**
   - `lib/widgets/sync_hero_card.dart` → `SyncHeroCard.build`, `mode != null` branch: the 160×160 `RadialGradient` circle in `Positioned.fill`, directly behind `TruLuraHaloAvatar(radius: 54, tone: TruLuraModeTone.sync)`, lerped with `auraGlow` (lines 108, 139-147).
   - `auraGlow` is `AuraStateController.auraColor`.
3. **Profile hero bloom — Vibe and intent.** `TruluraProfileHeroCard.build`: `BreathingGlow(glowColor: identityAccent)` wrapping the avatar `Stack` (lines 99-105).
4. **Profile hero outer ring — Vibe and intent.** `TruluraProfileHeroCard.build`: `CustomPaint(painter: _AvatarAuraRingPainter(accent: identityAccent))`, three ovals around the avatar (lines 113-117).
   - Source for 3 and 4: `identityAccent = _identityAccent(mood, intent)` (lines 40, 199-209). There `mood` is `user.moodTags.first` — the saved **Vibe**, defaulting to `'Reflective'` — and `intent` defaults to `'Social'`.

   > **Reversed 2026-09-14 for 3 and 4** by *Rulings — Vibe is Aura, Layer 1* at the end of this record: Vibe is Aura, so a Vibe-driven surround is correct. The intent input and the defaults are not settled by that ruling.

**Checked and not tinted by mood** (brand, mode or fixed colours):

- **`TruLuraHaloAvatar`, every call site:** `chat_list_screen.dart`, `chat_thread_screen.dart`, `new_message_screen.dart`, `trulura_conversation_tile.dart`, `trulura_profile_preview_sheet.dart`, `trulura_feed_components.dart`, `vent_screen.dart` (explore tone), `feed_card.dart` → `_FeedHeaderRow` (aura tone, with `BreathingGlow` from the mode palette `p.glowB`), and both branches of `sync_hero_card.dart` (sync tone).
- **`AuraRingAvatar`:** fixed cyan/pink in `explore_screen.dart`. The four uses inside `trulura_cinematic_components.dart` (`_WorldHeroFocal`, `AuraFeedCard`, `SyncMatchCard`, `ProfileHeroCard`) belong to components with no callers in `lib/`.
- **`_MiniAvatar`** in `sync_preview_panel.dart`: mode palette.
- **The compact feed card ring:** `home_feed_screen.dart` passes `TruLuraModeTone.aura` as `accentB`. Uncommitted.
- **`CircleAvatar`** in `profile_setup_screen.dart` and `sync_screen.dart`: neutral.

#### B. Invented numbers on or beside the avatar — fixed regardless

1. **Profile ring bands.** `AuraAvatar.ringColors` switches colour bands on `compatibility`, which Profile feeds from `_deriveAuraStrength` in `lib/screens/profile/profile_screen.dart` — a hash of the user id, 65–99 in practice (`65 + hash % 35`, then clamped to 55–99). The same number picks the `_AuraSignaturePill` text ("Deep aura rhythm", "Warm aura rhythm") in `trulura_profile_hero_card.dart`.
2. **Feed avatar % badge and orbit.** `_FeedHeaderRow.derivedCompatibility()` in `lib/widgets/feed_card.dart` hashes name, mood tag and photo to 60–94 and passes it as `TruLuraHaloAvatar(matchPercent:)`. That draws `_PercentBadge` and changes the `_HaloRingPainter` orbit alpha and dot size (`lib/widgets/trulura_halo_avatar.dart`).

#### C. Mood tint on cards, backgrounds and atmosphere — allowed by Class D

**Mood**, from `AuraStateController`:

- `lib/screens/home/home_hub_screen.dart`, the Home hub's `build`: `_gradientForMood(aura.mood)` tints the hub background gradient. It also tints the top tab bar's shadow and the selected tab indicator — see ambiguity 1.
- `lib/screens/home/home_feed_screen.dart` → `_HomeFeedScreenState.build`: `auraAccent` and `aura.auraColor` in the `DecoratedBox` background gradient around the feed.
- `lib/widgets/sync_hero_card.dart` → `SyncHeroCard.build`, legacy branch: the card glow, `TruLuraGlassCard(glow: …auraGlow…)`. The Connect button's `glowColor` also follows Mood — see ambiguity 2.
- `lib/widgets/sync_preview_panel.dart` → `MiniProfileCard.build`: `blendedGlow` as the card glow and the card's corner radial.
- `lib/screens/ai/ai_companion_screen.dart`: the screen background (`_TruCompanionScreenState.build`, `modeAccent`), and the 420px radial plus `_CompanionEnergyPainter` in `_PresenceSanctuaryState.build`. `_AuraCore.build`, the `_CompanionHeader.build` text colour and the `_AuraIntegrationPanel.build` icons and dividers — see ambiguity 3.

**Post mood tag**, from `MoodColors.glow` or the visual spec:

- `lib/widgets/feed_card.dart` → `_FeedCardState.build`: `moodGlow` in the card's depth shadow.
- `lib/widgets/feed_card.dart` → `_PostAuraBackground.build`: a `mood` radial in the card's background scene.
- `lib/widgets/feed_card_visual_spec.dart` → `FeedCardVisualSpec.fromPost`: mood branches pick `accentA` and `accentB`. The legacy card's background layers use them, and so does the vibe label pill beside the name in `_FeedHeaderRow` — a pill, not the avatar surround.
- `lib/screens/post/create_post_screen.dart` → `_ComposerWorldHeader.build`: the selected post mood ("Energetic" → gold) tints the header card. The 70px circle there holds a post-type glyph, not an avatar.

**Vibe**, not Mood:

- `lib/screens/home/home_feed_screen.dart` → `_moodAccentFor`: reads `user.moodTags.first` (Vibe) through `MoodColors.glow` into the feed background and `_SmartSwitchBanner(accent:)`.
- `lib/widgets/trulura_event_carousel_row.dart` → `TruluraEventCarouselRow.build`: the same Vibe read, tinting the event cards.
- `lib/widgets/trulura_profile_hero_card.dart` → `TruluraProfileHeroCard.build`: `identityAccent` tints the hero background radial, `_HeroAuraFieldPainter`, `_EnergyIndicator`, `_IdentityChip` and `_PresenceRhythmStrip`.

#### Ambiguities this ruling leaves open — not resolved here

1. **Navigation chrome.** The Home hub's selected-tab indicator and tab-bar shadow follow Mood. They are neither the avatar surround nor a card, background or atmosphere.
2. **Controls on a card.** The Sync hero's Connect button glow follows Mood. The ruling allows the card; it does not name the controls on it.
3. **The AI companion core.** `_AuraCore` is a large glowing orb with an aura glyph that stands in for the companion. If it counts as an avatar, its Mood gradient and glow are prohibited; if it is atmosphere, they are allowed. Its text and icon tints elsewhere on the screen are neither.
4. **Vibe.** The ruling names Mood. Sites A3 and A4 are prohibited either way, because the surround *represents Aura/brand glow* whatever drives it. For the Vibe-driven card and background tints in section C, the ruling is silent. *(Superseded 2026-09-14 by* Rulings — Vibe is Aura, Layer 1 *below: A3 and A4 are reversed.)*

---

### Rulings — 2026-09-14 (Class D): Vibe is Aura, Layer 1

**Decided by:** Darcell (Product Owner), 2026-09-14
**Classification: Product Owner Decisions, 2026 — Class D in the Product Owner's tracker.** Nothing above this section was rewritten; the passages it makes out of date carry a pointer here.

#### Ruling 1 — Vibe is Aura

> "Vibe is aura and mood is mood"

- **VIBE — CANONICAL:** Vibe, the value chosen at signup and stored in `profiles.vibe`, is Aura.
- **MOOD — unchanged:** Mood is Mood, and Mood is not Aura.

#### Ruling 2 — Vibe is Layer 1, Aura (identity)

> "Vibe is your aura who you are you personality energy character presence your aura is what tell the room your presence either you shine or you dont aura exposes who you are. Vibe is what that aura says about you"

- **VIBE LAYER — CANONICAL:** Layer 1, Aura — the persistent identity layer defined at the top of this record. Not Layer 2 (AuraState) and not Layer 3 (AuraPresentation).
- **Consequence, not decided:** Layer 1 already has storage, `identity_core` (`communication_style`, `core_values`, `relationship_preferences`). `profiles.vibe` is now Layer 1 storage too, in a different table and under a non-Aura name. Whether they become one home is open; nothing moves until the Product Owner rules.
- **Contradicted in docs and code as of 2026-09-14** (recorded, not resolved):
  - `TruLura_PO_Decision_Vibe_And_Temperament.md`, Ruling 1 of 2026-09-13, describes vibe as "expressive, changes often". Layer 1 is "persistent, slow-changing".
  - The migration `20260910_rename_vibe_status_to_temperament.sql` comments `profiles.vibe` as "the expressive, current-state value".
  - UI copy: "Choose your current vibe" (`lib/features/onboarding/onboarding_vibe_screen.dart:65`) and "Vibe is a session preference that shapes the tone of your feed and spaces." (`lib/screens/home/home_hub_screen.dart:698`).

#### Reversed: Class D inventory A3 and A4

- **What was found on 2026-09-14:** A3, the profile hero bloom (`BreathingGlow(glowColor: identityAccent)`), and A4, the profile hero outer ring (`_AvatarAuraRingPainter(accent: identityAccent)`), in `TruluraProfileHeroCard.build`, were listed as prohibited because Vibe drives them. So were the 2026-09-13 contradiction 2 ("Not brand glow") and re-classification row 2.
- **Reversed, and why:** Class D says the avatar surround *represents Aura/brand glow* and does not change with Mood. Under Ruling 1 Vibe is Aura, so a surround driven by Vibe is Aura shown where Aura belongs. The finding assumed Vibe was not Aura; that assumption no longer holds.
- **What the reversal does not cover** (checked in code, 2026-09-14):
  - **Intent also drives both sites.** `identityAccent` is `_identityAccent(mood, intent)`; `mood` is the saved Vibe (`user.moodTags.first`) and `intent` is `user.intents.first`. The rulings make Vibe Aura. They say nothing about intent.
  - **A default counted as an answer.** With no saved Vibe, `mood` falls back to `'Reflective'` and `intent` to `'Social'`, so the surround shows an Aura the person never chose.
  - **The names still say Mood.** The Vibe is read into a variable called `mood`, from a field called `moodTags`. The rename scope is listed in `TruLura_PO_Decision_Vibe_And_Temperament.md`, *Addendum — 2026-09-14*.
- **Not reversed:** A1 (profile hero ring and glow from `AuraStateController.auraColor`, which is Mood) and A2 (Sync hero glow from Mood) are still prohibited. B1 and B2 are still invented numbers.
- **Ambiguity 4:** the Vibe-driven tints in section C are no longer a Mood question. Whether Aura may tint a card or background was not ruled, and is not inferred here.

#### Still open: the vocabulary overlap moved, it did not disappear

- **Mood:** `enum Mood { reflective, flirty, calm, social, healing }` (`lib/providers/aura_state.dart:8`).
- **Vibe:** `Reflective, Dreamy, Calm, Flirty, Healing, Energetic, Creative` (`lib/features/onboarding/onboarding_vibe_screen.dart:22`).
- **Shared:** reflective, flirty, calm and healing — four of the five Mood values. Only `social` is Mood-only. Case is not a boundary: the live `profiles.vibe` holds a lowercase `reflective`.
- **Why it matters now:** this was a Vibe/Mood overlap. Under Ruling 1 it is an **Aura/Mood** overlap, exactly the pair this record exists to keep apart (DR-1 in the Product Owner's tracker). A bare `calm` cannot be attributed to Aura or Mood by inspection. The disjoint-vocabulary rule (`TruLura_PO_Decision_Vibe_And_Temperament.md`, Ruling 2 of 2026-09-13) applies, but no rename has been chosen. **Open.**
- **Found while checking, not decided:** `AuraState.vibeTags` is filled by `AuraStateController.defaultTagsForMood(mood)` (`lib/providers/aura_state.dart:113-121`). A field named for Vibe, which is now Aura, carries tags derived from Mood, and one of them, `grounded`, is also a temperament value.
