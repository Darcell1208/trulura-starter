# TruLura — Visual Study 05 Brief (Home)

Status: PROPOSED brief, drafted by Claude 2026-09-14 for the Product Owner's approval before any render is generated. Nothing in this brief is canonical. Decisions it relies on are cited to `claude/TruLura_Decision_Record_2026-09-14.md` (DR-1…DR-4) and the project's canonical-rules block; everything else is evidence, placeholder, or HOLD, and is labelled as such.

---

## 0. The question Study 05 exists to answer

> What is the one interaction or visual behaviour on TruLura Home that someone could screenshot without branding and we'd still recognise as TruLura?

Study 04 got the naming, the palette, the nav, and (in one variant) the brand position right, and still reads as a premium web app. So Study 05 is not "05 = 04 + polish." It changes the design grammar and tries to answer the question above. If the render is prettier and still doesn't answer it, the study has failed regardless of how it looks.

Working answer to test (P-2, PROPOSED): **two colour systems with a law between them** — the person's light constant (Aura), the room responding (Mood). Structural, not stylistic.

**Correction to the framing (2026-09-14):** the law as stated is only visible across *two states*. A single screenshot shows one state — a portrait in a coloured room — and someone holding that image alone sees one side of the law, not the law. So Study 05 runs **two tests, in order, and records which one carried recognition:**

- **Test 1 — single frame.** Frame A alone, watermark and placeholder covered. Can a viewer say what makes it TruLura without saying "purple" or "cosmic"? Whatever they name is the single-frame signature — and it will *not* be the Aura/Mood law, because the law isn't visible yet. Candidates already in evidence: the person's light visibly *not matching* the room's light (one frame shows two colour systems coexisting even if it can't show the constancy); micro-tags in the user's own words; the interface's voice ("Your Feed Is Taking Shape").
- **Test 2 — the pair.** Frames A and B side by side. Now the law is visible: same person, same light, different room. This is the honest test of the structural signature.

If Test 1 fails and Test 2 passes, TruLura is recognisable as a *behaviour* but not as a *frame* — worth knowing, and it changes what marketing, app-store screenshots, and the first screen a new user sees have to do. If both pass, the single-frame carrier is a finding to name. If both fail, the grammar change didn't work and the study says so.

---

## 1. Evidence base — Study 04 as read on 2026-09-14

Three variants, all read directly (not from another session's summary):

| Variant | Brand position | Watermark | Nav | Notes |
|---|---|---|---|---|
| `Screenshot 2026-09-14 091723.png` | `BRAND PLACEHOLDER / TRULURA / VISUAL IDENTITY TBD` — correct | `VISUAL STUDY 04 · TRUE LAUNCH STATE · NONCANONICAL` — present | rail + bottom bar both Home / Explore / Messages / More — one IA | best variant; the evidence base for 05 |
| `Screenshot 2026-09-14 091709.png` | **none** — rail opens with avatar; ∞ mark in bottom-bar centre | present | rail Home / Explore / Messages / More; bottom bar Home / Explore / ∞ / Messages / More | ∞ is the boards' heart/infinity concept (Class C) rendered as if settled |
| `Screenshot 2026-09-14 083815.png` | generated TruLura wordmark + tagline — **regression** | **absent** — footer is brand copy, not the study watermark | rail only | non-compliant on two counts; do-not-carry-forward |

What held across all three (KNOWN): three-column desktop composition; five Mood chips Calm / Social / Flirty / Reflective / Healing with dots in the DR-2 hue families (exact hex not verifiable from JPEG); honest launch state — one real post, two real people; "Your Feed Is Taking Shape" present.

What P-1 predicted and 04 confirmed: every detail that could be corrected inside the three-column grammar was corrected, and the composition still reads as generic. The composition is the remaining variable.

### Defects carried from Study 04

- **D-1 Undeclared person-descriptor chips.** `Creative` / `Mindful` (091723, 091709), `Creative Soul` / `Mindful Explorer` (083815) under the two people. No concept behind them — not Mood (DR-3), not temperament, not an archive micro-tag. `Creative` already exists in the post-composer's mood list (`create_post_screen._moods`). **Live risk, not a documentation gap:** drawing an unnamed chip a third time is how it becomes real. Study 05 either declares what that slot is or leaves it empty.
- **D-2 Ring colours undeterminable.** Three people, three ring colours (gold, magenta, orange). DR-1 permits per-person Aura colour only when the source is Aura. From a static render the source cannot be established — Aura, Mood, or an image generator choosing pleasing hues, the last being most likely. **Record as: not a violation, not a pass, undeterminable.** Study 04 must not be cited as evidence that the DR-1 rule works.
- **D-3 `Your Aura — Balanced`.** `Balanced` as an Aura reading sits one word from `Balanced energy`, an existing social-preference option in code. Unlabelled word; potential Class E.
- **D-4 Brand mark drift.** One variant invented a wordmark; one rendered the ∞ concept; one used the placeholder correctly. Only the placeholder is compliant.
- **D-5 Watermark omitted** on 083815.

---

## 2. Constraints — apply during generation, then verify after

### Canonical (must hold; cite, don't re-derive)

- DR-1: the avatar and all light that belongs to it — ring, halo, glow, bloom, surrounding radiance — is Aura, never Mood. Mood lives in its labelled chip/dot or in clearly separate environmental treatment. A hero surface may respond to Mood only where that treatment stays visually distinct from the avatar's Aura presence.
- DR-2: Mood palette — Reflective `#8B5CF6→#6366F1`, Flirty `#FF4D9D→#FF7AB8`, Calm `#7DD3FC→#38BDF8`, Social `#FB923C→#F59E0B`, Healing `#34D399→#86EFAC`. Categorical UI semantics; not Aura colours.
- DR-3: the five Moods are Reflective / Social / Calm / Flirty / Healing. No Energized, no Low Energy in this vocabulary.
- Vibe and temperament are distinct concepts with disjoint vocabularies. No concept reads another's storage.
- Accessibility is not a degraded TruLura: the study must ship a reduced-motion / static-Aura / minimal-effects companion frame that is *equivalent*, not lesser.
- Study artefact rule: visible `VISUAL STUDY 05 · NONCANONICAL` watermark on every frame; companion study record (§5).

### Grammar change (PROPOSED — the point of 05)

1. **No rails.** Drop the three-column composition. One thing at a time, depth behind it. Portrait grammar on whatever canvas is used; the platform question (desktop Home yes/no) is Class C and this study does not decide it — it only stops manufacturing destinations to fill a rail.
2. **People and emotional/social context are the anchors,** not modules. Inhabited with two users — not populated by fake activity.
3. **Aura gets environmental presence beyond a meter — with one colour.** There is no Aura system to draw from at render time, so per-person Aura variation is **untestable** in this study; asking for a documented source would only produce "generator-chosen" in better handwriting (Study 04's D-2, reproduced). Rule for 05: **one documented Aura colour, specified in the prompt, identical on every portrait in every frame.** Recommended: `#7E5FEF` (Violet Aura, the one hex the brand board supplies) — PROPOSED; the Product Owner may substitute. Per-person Aura variation is deferred until an Aura colour source exists in product logic, and the study record says so. No `Balanced` meter until D-3 is resolved.
4. **Mood affects the environment, never the avatar surround.** This is the frame that answers §0: show the same person twice, Aura constant, room shifted by Mood. If the study can only afford one hero frame, it is this pair.
5. **Voice, not modules — and the sentence must actually be written.** "Your Feed Is Taking Shape" is a voice — keep it. Retire dashboard cues ("Profile Progress", "Tips for a Better Experience", "New Here? Try These") as *modules*. But at true launch a new user has no feed and needs direction; if the direction isn't written into the frame, **Frame A reads as empty rather than atmospheric** — that is a named failure mode for A, the way "life turned off" is for C. So the prompt must include the actual next-step copy, in TruLura's voice, placed where a module would have been. PROPOSED copy, for the Product Owner to keep or replace — one line:
   - *"Start where you are. Say one true thing, or set how you're feeling — the room will listen."*
   A second line naming the two present users was struck: copy that is load-bearing on network size (intimate at two, meaningless at two hundred, broken at zero) will be rewritten, which means it is a placeholder wearing the voice's clothes, not the voice. Copy for Home must survive any network size.
   **Note for the record:** "the room will listen" states the signature in words — it tells the user the environment responds to them. Test 1 must therefore ask whether Frame A needs the sentence to carry that meaning or whether the image carries it alone. **If the copy has to say it, the visual didn't.** Record this as a Test 1 finding either way: *signature carried by image / carried by copy / carried by neither.*
   Review checks that a first-time viewer of Frame A can say what to do next without a checklist module telling them. (PROPOSED; the Product Owner may keep any of the retired modules instead.)
6. **Archive DNA, where product-safe:** expressive micro-tags in the user's own words; layered portrait treatment; organic light trails; irregular, softer composition. Micro-tags are evidence from the boards — render them as *the user's words*, never as a taxonomy.
7. **Launch honesty preserved:** one real post, two real people, no invented crowd.

---

## 3. HOLDs — placeholders that must stay visibly placeholders

| HOLD | Freeze boundary for Study 05 |
|---|---|
| Reaction vocabulary (Spark · Glow · Echo · …) | Render at most one generic reaction affordance with no label, or a `[REACTION TBD]` placeholder. Do not name reactions. |
| Nav labels / IA | Reuse Study 04's `Home / Explore / Messages / More` **as placeholder text only**, watermarked in the study record as HOLD. One nav, not two. |
| Swipe vs resonance | Home does not depict either. No card stack, no "sync field." |
| Brand mark | `BRAND PLACEHOLDER / TRULURA / VISUAL IDENTITY TBD` block, exactly as 091723. No wordmark, no ∞. |
| Person-descriptor chip (D-1) | **Empty.** No chip under a person unless the Product Owner names the concept first. |
| Aura reading / meter (D-3) | Omit. |
| Desktop vs portrait platform | Study 05 uses portrait grammar; it does not claim TruLura is phone-only. |
| Modes (Friendship / Dating / Creator / Luxe / Social) | Not on Home in this study. |

---

## 4. Deliverables

- **Frame A — Home, immersive default.** One person (the Product Owner's real profile as in 04), Aura constant, Mood = Calm environment.
- **Frame B — same Home, Mood = Reflective.** Identical Aura presence; only the environment changed. Frames A and B side by side are the screenshot test.
- **Frame C — Frame A at reduced motion / static Aura / minimal effects.** This is likely the hardest frame and it is a **test, not a compliance checkbox.** The signature is "the room responds to Mood, Aura stays constant." Removing motion and glow animation removes one channel that A relies on; C must carry the same emotional difference through light, depth, and composition alone. **Named failure mode:** C reads as "A with the life turned off." If that happens, the accessibility rule has failed — and that failure is more informative than anything A or B can produce, because it means the signature was living in the motion channel rather than in the structure. Report it as a finding, not as a defect to be patched with more glow.
- **Study record** (§5).

No additional variants. Three frames, one record.

---

## 5. Study record — required contents

For each frame: study id and watermark confirmation; the DR-1 check stated as one of **PASS / FAIL / UNDETERMINABLE** with the reason; **confirmation that every ring/halo is the single specified Aura colour** (any deviation is a defect, not a variation), plus the standing note that per-person Aura variation is deferred until an Aura colour source exists; the Mood shown and where its colour appears (environment only); for Frame A, the explicit verdict **directed / empty** (does a first-time viewer know what to do next without a module?); for Frame C, the explicit verdict **carries the signature / reads as A-with-the-life-turned-off**, with what carried it or what didn't; the Test 1 verbatim answer and what it named; the Test 1 signature-carrier verdict **image / copy / neither** (run once with the direction line visible and once with it covered); HOLD placeholders present and how they are marked; vocabulary present (every chip, label, and tag listed, each mapped to a declared concept or marked `undeclared — must be removed`); defects; do-not-carry-forward list.

Independent verification (after generation, by a reviewer who did not write the prompt): read all frames; confirm the watermark on each; confirm no wordmark and no ∞; confirm no chip under any person; confirm Frame A and B differ only in environment; confirm every ring in every frame is the one specified colour; judge Frame C against the named failure mode before judging anything else about it. Report as KNOWN with what was seen, not as "looks compliant."

---

## 6. Success criterion — two tests, in order

Show to someone who has seen Studies 01–04, watermark and placeholder block covered.

1. **Frame A alone.** Ask what makes it TruLura. Record the answer verbatim. "Purple" / "cosmic" / "it's the same but nicer" = Test 1 fails. Anything structural or voice-based = Test 1 passes; record *what* carried it. Run it twice — once with the direction line covered, once visible — so the record can say whether the image or the copy carried the signature.
2. **Frames A and B together.** Ask what changed and what didn't. If they can say the person stayed and the room changed — in any words — Test 2 passes.
3. **Frame A, then Frame C.** Ask if it's the same product. "Yes, quieter" passes. "It's the same but with everything turned off" fails.

Study 05 has done its job if Test 2 passes and Test 3 passes. Test 1 is the open question the study exists to answer, not a pass/fail gate — but its result decides what the *first* screen a new user ever sees has to carry, so it is recorded either way.
