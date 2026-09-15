# TruLura Decision Record — 2026-09-14

Class D — fresh Product Owner decisions. Each entry carries the Product Owner's words verbatim; explanatory notes below a quote are Claude's and are not part of the decision. Documentation only; no code was changed for this record.

Supersession scope (per DR-4 below): each record supersedes the Blueprint only on the points it explicitly names.

---

## DR-1 — Avatar presence is Aura, never Mood

**Product Owner, verbatim:**

> "The avatar and all light that visually belongs to it—ring, halo, glow, bloom, or surrounding radiance—represent Aura and never Mood; Mood belongs in its labeled chip/dot or in clearly separate environmental treatment, and a hero card may respond to Mood only where that treatment remains visually distinct from the avatar's Aura presence rather than washing the avatar and its surrounding field in the Mood color."

**Product Owner, on scope:** "Extends the existing 'ring is Aura, not Mood' line."

*Note (Claude):* extends the canonical rule already in the project instructions — "Ring/halo/glow around an avatar is Aura brand glow. Mood is a chip with a colored dot. Mood never tints the avatar surround." — by naming halo, bloom, and surrounding radiance explicitly and by defining the hero-card test: Mood treatment must remain visually distinct from the avatar's Aura presence.

---

## DR-2 — Mood palette (five moods, stop-1 → stop-2)

**Product Owner, verbatim:**

> "MOOD PALETTE — five confirmed, stop-1 → stop-2:
> Reflective #8B5CF6 → #6366F1
> Flirty     #FF4D9D → #FF7AB8
> Calm       #7DD3FC → #38BDF8
> Social     #FB923C → #F59E0B
> Healing    #34D399 → #86EFAC
>
> PO reasoning: Social moves warm rather than pushing Reflective darker. Reflective owns violet, Calm blue, Healing green, Flirty pink, Social introduces warmth."

*Note (Claude):* these values were proposed in this session and confirmed by the Product Owner above; the confirmation is the decision. Stop-1 hues: Reflective 258°, Flirty 333°, Calm 199°, Social 27°, Healing 158°; minimum adjacent hue gap 41°. Prior state (for the record, not authoritative): Reflective `#553C9A→#3B82F6`, Flirty `#FF5FA2→#8B5CF6`, Calm `#B7D8FF→#6EA8FE`, Social `#8B5CF6→#6D28D9`, Healing `#2EC4B6→#7BC47F`; Reflective and Social stop-1 were 2° apart.

---

## DR-3 — The fifth Mood is Social

**Product Owner, verbatim:**

> "FIFTH MOOD — Social. Reflective / Social / Calm / Flirty / Healing. Energized and Low Energy belong to an energy dimension, not this vocabulary."

*Note (Claude):* resolves the discrepancy between the design boards (which show Healing / Reflective / Flirty / Calm / **Energized** on one board and Reflective / Flirty / Calm / Low Energy / Social on another) and the build (`enum Mood { reflective, flirty, calm, social, healing }`). The build's set is the confirmed set. "Energy dimension" is not further defined by this record; the Blueprint's §12.7 Social Battery Framework is the nearest existing concept, but whether Energized / Low Energy map onto it is not decided here.

---

## DR-4 — Authority order between decision records and the Blueprint

**Product Owner, verbatim:**

> "Decision records supersede the Blueprint only on the specific points they explicitly name; the Blueprint remains authoritative everywhere a later applicable decision record does not supersede it. Related concepts are not implicitly superseded."

*Note (Claude):* the supersession scope and the non-implication clause are one sentence by design; quote the whole sentence, never the first half alone.

---

## Also recorded — carries to Visual DNA

**Product Owner, verbatim:**

> "The five Mood colors are categorical UI semantics, not Aura colors. Resemblance to the Adaptive Aura Color System does not merge the systems."

*Note (Claude):* the Adaptive Aura Color System (design boards; ten named palettes — Cosmic Blue, Sunset Amber, Dream Violet, Rose Glow, Emerald Calm, Moonlight Silver, Aurora Pink, Midnight Indigo, Soft Gold, Reflective Lavender) is Class C design material. Several DR-2 hues resemble entries in it. Per this record, that resemblance is not a link.

---

## Scope report — sites in `lib/` that hardcode the pre-DR-2 mood hues

Read-only. Nothing changed. Source: fresh clone of `github.com/Darcell1208/trulura-starter`, HEAD `051b27f0` (2026-09-07 22:27 -0400, "Give user_states.mood_tag one writer and one vocabulary"). **Caveat:** the dev build inspected earlier today may include uncommitted local changes not in this clone; the `home_hub_screen.dart` gradients below match what the running bundle served, so at least that file is current.

### Direct hex hits (grep for the nine old values, case-insensitive)

| File:line | Value | Concept |
|---|---|---|
| `lib/screens/home/home_hub_screen.dart:115` | `0xFF553C9A, 0xFF3B82F6` | Mood.reflective gradient |
| `lib/screens/home/home_hub_screen.dart:117` | `0xFFFF5FA2, 0xFF8B5CF6` | Mood.flirty gradient |
| `lib/screens/home/home_hub_screen.dart:119` | `0xFFB7D8FF, 0xFF6EA8FE` | Mood.calm gradient |
| `lib/screens/home/home_hub_screen.dart:121` | `0xFF2EC4B6, 0xFF7BC47F` | Mood.healing gradient |
| `lib/screens/home/home_hub_screen.dart:123` | `0xFF8B5CF6, 0xFF6D28D9` | Mood.social gradient |
| `lib/providers/aura_state.dart:109` | `0xFF7BC47F` | Mood.healing (see below) |
| `lib/theme.dart:381` | `0xFF8B5CF6` (with `F472B6`) | theme gradient token — **not mood** |
| `lib/theme.dart:569` | `0xFF6D28D9` | `darkPrimaryContainer` — **not mood** |

The five `home_hub_screen.dart` lines are `_gradientForMood(Mood)` and are the only place the current gradient pairs live. `theme.dart` shares two hex values by coincidence; those are theme tokens and should not be touched by the palette change.

### Second mood-colour map (different hues, same five moods)

`lib/providers/aura_state.dart:103–110`, `AuraStateController.colorForMood(Mood)`:

```
Mood.reflective => 0xFF6E7FBF
Mood.flirty     => 0xFFE45C96
Mood.calm       => 0xFF5DA8A3
Mood.social     => 0xFFFFB457
Mood.healing    => 0xFF7BC47F
```

Only `healing` matched the grep; the other four are hues that appear nowhere else. So the palette change has **two** maps to update, not one, and they currently disagree with each other. Classification corrected per Product Owner: this is a **duplicate implementation** of one map (one concept, two storage locations), not several words naming one concept, which is a different failure class.

### Finding that bears on DR-1, not just DR-2

`colorForMood` is used to set **`auraColor`** (`aura_state.dart:36, :95, :140`) — the Aura colour is derived from the current Mood. `auraColor` is then consumed by:

- `lib/widgets/aura_avatar.dart:40–90` — `ringColors(aura.auraColor)` and the ring glow (`auraColor.withValues(alpha: 0.18 * pulse)`)
- `lib/widgets/sync_hero_card.dart:108`, `lib/widgets/sync_preview_panel.dart:143` — `auraGlow`
- `lib/screens/home/home_feed_screen.dart:800, :816`
- `lib/screens/ai/ai_companion_screen.dart` — eight sites

In the current build, **the avatar ring colour is the Mood colour.** That is the pattern DR-1 prohibits, and it is **failure class: one concept reading another concept's storage** (Aura presentation reading Mood). Reported here; not changed. Whether the fix is "Aura gets its own colour source" or "the ring stops varying" is implementation, but it is required by DR-1 regardless of which palette values land.

### Third "mood" vocabulary in `lib/theme/mood_colors.dart`

`cheerful / energetic / calm / romantic / focused / creative` — six string-keyed cases, none of which (except `calm`) is a DR-3 mood. Imported by `lib/core/theme/app_theme.dart`, `lib/screens/home/home_feed_screen.dart`, `lib/widgets/trulura_event_carousel_row.dart`, `lib/widgets/feed_card.dart`. This is **failure class: one word naming several concepts** (here, "mood" on two); whatever this file colours, it is not the DR-3 Mood. Out of scope for the palette change; flagged so it isn't mistaken for a third place to apply DR-2.

### Not found

No hardcoded mood hues in `lib/theme/trulura_theme.dart`, `lib/core/theme/app_theme.dart`, or any widget other than those listed. No mood colours in assets or JSON.

---

## Clone freshness — checked, and the gap is real

`git fetch` + `git ls-remote`: local HEAD `051b27f0` **equals** `origin/main` HEAD; `main` is the only remote branch. So the clone is not behind the remote — the remote itself is a week behind the running dev build. Evidence that the dev build is ahead of `origin/main`:

- The compiled bundle served by `localhost:8123` earlier today contains `enum TruTemperament { oldSoul, mending, contemplative, radiant, grounded, mysterious }` and a `_persistTemperament` probe over `["temperament","vibe_status"]`.
- `origin/main` has **no `TruTemperament`**. `lib/models/user.dart` at HEAD has `enum TruVibeLabel { oldSoul, healing, reflective, radiant, grounded, mysterious }`, and no temperament probe.

So the Dart half of the `vibe_status → temperament` rename (and the `TruVibeLabel → TruTemperament` enum rename that went with it) exists only in an uncommitted or unpushed working tree. **Consequence for the Code session:** if it works from `origin/main` it will find neither the probe it was told to delete nor the `temperament` field the migration now expects — and the migration applied today would break `origin/main`'s reads of `vibe_status` (the read-side fallback `?? json['vibe_status']` would return null → default `oldSoul`, i.e. failure class: default counted as an answer). The uncommitted work must be committed and pushed before anyone else touches this area.

---

## Incident — schema moved ahead of the code that expects it

**State as of this record:** Supabase `profiles.temperament` exists (renamed from `vibe_status` today). `origin/main` @ `051b27f0` still reads `vibe_status` and has no `TruTemperament`. The code that matches the schema is in an unpushed working tree on the Product Owner's machine.

**Exposure:** any build from `origin/main` against the migrated database reads `temperament ?? vibeLabel ?? vibe_status` → all three null → `TruVibeLabel.oldSoul` for every user, silently, with no error. Failure class: default counted as an answer, at scale.

**How it happened:** the Dart rename was reported as done; the migration was applied on that basis; nobody — including Claude, who applied it — checked that "done" meant "pushed." Claude had only seen the rename in the compiled dev bundle, which is not evidence of repository state. Cross-session assumption, textbook form. Claude's part: applying a schema change after verifying the *database* side thoroughly and the *repository* side not at all.

**Resolution order (Product Owner):** "That needs the local tree pushed before anything else touches this area."

**Fallback if the push can't happen promptly:** reverting the migration (`alter table public.profiles rename column temperament to vibe_status`) restores `origin/main` compatibility; the dev build would fall back to its probe and keep working. Not done — the ruling is push-first — but it is the one-line safe state if a deploy from origin becomes possible before the push lands.

**Prevention:** a migration that renames a column the app reads is Class-B-adjacent — it requires the matching code to be *on origin* first, not merely written. Add to the pre-migration check: `git ls-remote origin HEAD` equals the commit that contains the code change.

---

## Incident update — push landed; two corrections to this record

**KNOWN, checked 2026-09-14 (later):** `origin/main` moved `051b27f0 → 57276b88`, 48 commits. `lib/models/user.dart:408` on origin now has `enum TruTemperament`; `fromJson` reads `temperament` first (`user.dart:210`). **The exposure in the Incident section above is closed** — a build from origin against the migrated database reads the right column. The `_persistTemperament` probe is still present on origin (`user_service.dart:164`) and is now safe to delete.

**Correction 1 — the probe was not an accident.** `supabase/migrations/20260910_rename_vibe_status_to_temperament.sql` exists on origin, marked *NOT YET APPLIED*, and documents a deliberate three-step plan: Step 1 (Dart) move the temperament write out of the un-tolerant `safePayload` into a write that tries `temperament` then falls back to `vibe_status`, so one build works against both schemas; Step 2 (SQL) rename; Step 3 (Dart) delete the fallback. The probe *was* Step 1, by design — "half-finished rename" in this record was Claude's characterisation from the compiled bundle, and it was wrong about intent. The Product Owner's ruling (finish the rename, delete the probe) is Step 2 + Step 3 of the repo's own plan, so the decision stands; the description of why the 400 existed is withdrawn.

**Correction 2 — the migration Claude applied is a subset of the repo's.** `rename_profiles_vibe_status_to_temperament` (applied via MCP) did only the column rename and a comment. The repo's migration file also: (1b) rewrites overlapping values `temperament='reflective'→'contemplative'` and `'healing'→'mending'`; sets a fuller column comment; and (2) **drops `profiles.persona`**. Verified now, read-only:

| Check | Result |
|---|---|
| profiles columns of interest | `persona, temperament, vibe` — rename done, **persona still present** |
| temperament values | `grounded ×1, oldSoul ×2` |
| overlap (`reflective`/`healing` in temperament) | `0` — 1b has nothing to rewrite today, but the guard is the point |
| vibe values | `Dreamy ×2, reflective ×1` |
| persona non-null rows | `0` |

The repo's migration is idempotent and guarded; running it now would skip the rename (already done), run the 1b updates (no-op today, protective going forward), set the comment, and drop `persona`.

**IRREVERSIBLE OPERATION — decide before anything runs:** `alter table public.profiles drop column if exists persona`. The file is a single transaction, so "apply the file" *is* "drop persona." It is all-null on every row and no code reads or writes it (per the file's own note, re-verify before trusting), so the data loss is nil — but a dropped column is not restored by re-running a script, and that is the test. This needs a Product Owner yes or no on its own line, not folded into the migration recommendation.

Recommendation (PROPOSED), conditional on that answer:
- **Yes, drop persona:** the Code session applies `20260910_rename_vibe_status_to_temperament.sql` unchanged through the normal migration path (so migration history matches the repo), then runs the file's POST-APPLY VERIFICATION block and reports its *output*, not the statement result. Expected: columns `temperament, vibe` only; overlap count 0.
- **No, keep persona for now:** the Code session derives a migration containing only 1b and the column comment, applies that, and the persona drop stays in the file as a separately-dated, separately-approved step.

**Pattern, for prevention — second occurrence in two days:** the compiled bundle shows what the code *does*, not *why*. Intent — the three-step plan, the "NOT YET APPLIED" marker, the documented vocabularies — lives in the repo, in migration headers and `docs/`. Diagnosing from compiled output without reading the repo produced "half-finished rename" here and "missing-column error, fields never persisted" earlier the same day; both withdrawn. Rule going forward: a diagnosis from a bundle is INFERRED until the corresponding source and its comments have been read; the repo, not the bundle, is where "why" is checked.

**Also surfaced by the migration file:** the repo's documented *vibe* vocabulary is `Reflective, Dreamy, Calm, Flirty, Healing, Energetic, Creative` (per `docs/TruLura_PO_Decision_Vibe_And_Temperament.md`, in the repo, not in this project). Two consequences: `Creative` is a **Vibe** value, which makes Vibe the leading candidate concept for the undeclared person-descriptor chip in Study 04 (D-1) — the Product Owner still has to say so; and this vibe vocabulary shares `Reflective`, `Calm`, `Flirty`, `Healing` with the Mood vocabulary (DR-3), which is an overlap of the failure class *one word naming several concepts*, between two concepts the canonical rules say must be disjoint. Logged as Class C: whether the Vibe vocabulary changes, the Mood vocabulary changes, or the overlap is accepted for two concepts that never share storage.

---

## PROPOSED — design findings for the Study 05 brief (not decisions)

Both entries below are Claude's proposals, refined with the other review session. Neither carries Product Owner words; neither is canonical. They are recorded so the Study 05 brief inherits them rather than rediscovering them.

**P-1 — Composition is causal, not cosmetic.** Studies 01, 02A, 02B and 03 are three-column desktop compositions (left rail, centre feed, right sidebar). Every one of the 37 design boards in the project is portrait phone; the three-column layout has no ancestor in the project's design evidence. More than aesthetics: a rail plus a bottom bar must be *filled*, so the composition demands more destinations than the product has — which is structurally why two competing IAs kept appearing across the studies and had to be corrected twice. On portrait there is one nav and the question does not arise. Consequence for Study 05: carry the portrait grammar (one thing at a time, depth behind it, no rails) onto whatever canvas it uses. Whether TruLura ships a desktop Home at all remains Class C; the boards being phone-shaped is evidence for portrait-first, not a decision.

**P-2 — The recognition test, and where it currently fails.** The code consequence first: the build runs TruLura's structural signature backwards. `colorForMood → auraColor → avatar ring` means the *person* changes colour with Mood and the *room* does not. DR-1 requires the opposite — the person's light constant (Aura), the environment responding (Mood). So DR-1/DR-2 is a behaviour change, not a palette change, and until it lands no render can pass the test below because the underlying rule is inverted at runtime. The test: what could someone screenshot from Home, with no wordmark, and still know it is TruLura? Proposed answer: two colour systems with a law between them — a portrait whose ring never shifts, in an atmosphere that visibly has. It is structural, not stylistic, which is why it survives a screenshot; "purple cosmic social app" does not. Secondary candidates: micro-tags in the user's own voice ("Trust Repair Mode", "My Softness Is Earned"); launch-scale honesty ("Your Feed Is Taking Shape") as a voice rather than a placeholder.

---

## Study 04 — read 2026-09-14, three variants

Read directly by Claude (not from another session's summary). Full review and defect list carried into `claude/TruLura_Study05_Brief.md` §1. Points that belong in this record:

- **Ring colours: UNDETERMINABLE.** Three people, three ring colours (gold, magenta, orange). DR-1 permits per-person Aura colour only if the source is Aura. A static render cannot establish the source — Aura, Mood, or generator-chosen hue, the last most likely. Recorded as *not a violation, not a pass, undeterminable*. **Study 04 is not evidence that DR-1 works.**
- **Undeclared chips are a live risk.** `Creative` / `Mindful` / `Creative Soul` / `Mindful Explorer` under people, with no declared concept; `Creative` collides with the post-composer mood list. Study 05 leaves the slot empty unless the Product Owner names the concept.
- **P-1 confirmed by outcome:** naming, palette, nav, and (one variant) brand position were all corrected within the three-column grammar and the result still reads as premium web app.
- Variant `083815` lacks the study watermark and carries an invented wordmark — non-compliant on both counts; do-not-carry-forward.

Duplicate `TruLura_Decision_Record_2026-09-14_2.md` at the project root (identical content) was deleted 2026-09-14 so that this file is the only decision record for the date.

---

## Class C — open after this record

- **What `TruIdentityMode`, `TruProfileType`, `TruLuraMode`, and `Intent` become.** DR-3 fixes the Mood vocabulary as Reflective / Social / Calm / Flirty / Healing, so `social` as a Mood value is decided; the other four uses of `social` are the ones that have to move. Three of the four (`TruIdentityMode`, `TruProfileType`, `TruLuraMode`) are the drawer's Modes under three enum names — one rename once the surviving enum is chosen. `Intent.social` ("why I joined") is a separate concept from Mood ("how I am right now") and needs its own word.
- **Whether `mood_colors.dart` / `create_post_screen._moods` are Mood or a separate post-tone concept.** They share only `calm` with DR-3.
- **Whether `TruEmotionalPresenceKind` is a presentation layer over Mood + `EnergyLevel` or a fourth concept.** Its `lowEnergy` duplicates `EnergyLevel.low` — the collision DR-3's energy-dimension ruling exists to prevent.
- **Whether `matchmaking_profiles.intent` should follow identity mode** (carried from the write audit).
- **Mood / Vibe vocabulary overlap.** Repo-documented Vibe vocabulary: `Reflective, Dreamy, Calm, Flirty, Healing, Energetic, Creative`. Mood (DR-3): `Reflective, Social, Calm, Flirty, Healing`. Four of five Mood values are also Vibe values — near-total overlap between two concepts the canonical rule requires to be disjoint by inspection. Same problem as vibe-vs-temperament, one concept over, unresolved. Options are the same shape as before: rename the overlapping Vibe values, rename Mood values (DR-3 would need reopening), or rule that two concepts which never share storage may share words (which weakens "detectable by inspection"). Class C until the Product Owner rules. Note: this overlap likely explains Study 04's undeclared person chips — `Creative` is a Vibe value — so D-1's candidate concept is Vibe, pending declaration.
- **Drop `profiles.persona`** — irreversible; yes/no needed before the repo's rename migration file can be applied as written (see Incident update).

---

## Vocabulary sweep — enums and constant lists in `lib/`, judged by meaning

All 60 enums in `lib/` were listed; the ones that name an emotional, energetic, or mode-like state are below. Source: `origin/main` at `051b27f0`; the bundle's `TruTemperament` is noted where it differs.

| # | Vocabulary | Values | Where | Overlaps with |
|---|---|---|---|---|
| 1 | `Mood` (enum) | reflective, flirty, calm, social, healing | `providers/aura_state.dart:8` | — canonical per DR-3 |
| 2 | `mood_colors.dart` (string switch) | cheerful, energetic, calm, romantic, focused, creative | `theme/mood_colors.dart` | #1 on `calm` only |
| 3 | `_moods` (List<String>) | Cheerful, Energetic, Calm, Creative, Adventurous, Focused | `screens/post/create_post_screen.dart:45` | #2 on five of six; differs (`Adventurous` vs `romantic`) |
| 4 | `TruVibeLabel` (enum, HEAD) | oldSoul, healing, reflective, radiant, grounded, mysterious | `models/user.dart:379` | **#1 on `healing`, `reflective`** |
| 4′ | `TruTemperament` (enum, dev bundle only) | oldSoul, mending, contemplative, radiant, grounded, mysterious | not on origin | disjoint from #1 — the local rename already fixed the #4 overlap |
| 5 | `TruEmotionalPresenceKind` (enum) | emotionallyOpen, lowEnergy, sociallyOverwhelmed, softPresence, quietMode, glowingSocially, reflective, recharge, hidden | `models/emotional_presence_state.dart:1` | #1 on `reflective`; #6 on `lowEnergy` |
| 6 | `EnergyLevel` (enum) | low, medium, high | `providers/aura_state.dart:10` | the "energy dimension" DR-3 points to |
| 7 | `Intent` (enum) | social, dating, healing, networking | `providers/aura_state.dart:12` | #1 on `social`, `healing`; #8 on `social`, `dating` |
| 8 | `TruIdentityMode` (enum) | social, friendship, dating, creator, luxe, vent | `models/user.dart:350` | #9, #10 |
| 9 | `TruProfileType` (enum) | social, dating, creator, luxe | `models/identity/identity_profile.dart:71` | #8 minus friendship, vent |
| 10 | `TruLuraMode` (enum) | social, aura, sync, vent, trending | `providers/trulura_mode_controller.dart:7` | #8 on `social`, `vent` |

Findings, by class:

- **One word naming several concepts:** `social` is a Mood (#1), an Intent (#7), an IdentityMode (#8), a ProfileType (#9), and an app Mode (#10) — five concepts. `reflective` is a Mood (#1), a VibeLabel at HEAD (#4), and an EmotionalPresenceKind (#5). `healing` is a Mood (#1), a VibeLabel at HEAD (#4), and an Intent (#7). `calm` is a Mood (#1) and a post-mood (#2, #3). Under the naming rule ("vocabularies for distinct concepts must be disjoint, so a value in the wrong column is detectable by inspection"), every one of these is a place where a misfiled value is undetectable.
- **Several words naming one concept:** #8 / #9 / #10 are three enums for what the drawer calls Modes; #2 / #3 are two lists for the post-composer mood, differing in one value. Whether #2/#3 are the same concept as #1 (Mood) or a separate "post tone" is a Class C question — they share only `calm`, so by meaning they look like a different thing wearing the word "mood".
- **One concept reading another's storage:** `AuraStateController.colorForMood → auraColor → avatar ring` (above). Also, at HEAD, `User.fromJson` reads `temperament ?? vibeLabel ?? vibe_status` — three keys for one field, two of them from other concepts' names.
- **Not a violation, but note:** #5 `TruEmotionalPresenceKind.lowEnergy` and DR-3's "Energized and Low Energy belong to an energy dimension" point at the same idea; #6 `EnergyLevel` is that dimension in code today. Whether #5 is a presentation layer over #1+#6 or a fourth concept is not decided.
