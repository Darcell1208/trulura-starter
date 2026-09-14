# TruLura — Design Screenshot Extraction

**Source:** 37 screenshots in the project folder, dated 2026-09-12.
**Method:** Every screenshot viewed directly. Concept names grepped against `TruLura_Blueprint_v21_reconciled.md` for coverage counts.

## Status of this document

Everything below is **Class C — design material, not decided product**. These are mockups and concept boards. None of it carries a Product Owner decision quote, and several items conflict with each other across screenshots (gift prices differ between two boards, subscription tiers differ between three). Nothing here should enter the Blueprint without being resolved and confirmed.

**Blueprint caveat:** coverage counts are against `TruLura_Blueprint_v21_reconciled.md`, which is *not* the canonical repo file — it has no Section 27. Section 27's eight decisions cover revenue architecture, TruScore, Vent gifting, enforcement, group size, TruLuxe qualification, and AI training, so they shouldn't change the counts below. But the counts were not run against the repo's file.

---

## 1. Accessibility — the largest gap

Three fully-designed modes, each with a complete interface. **Blueprint mentions: zero for all three.**

**ADHD Focus Mode** — focus timers (25:00 work / 05:00 break), session counter, Distraction Shield toggle, Simplify Interface, Reduce Motion, Notification Filter, focus presets (Deep Work, Study Mode, Creative Flow, Light Focus, Quick Task), Gentle Reminders, ambient sound selection, "Save My Focus Settings."

**Autism Friendly Mode** — organized as *Your comfort. Your way.* Four benefit cards: Predictable, Reduced Overwhelm, Clear & Structured, Emotionally Safe. Toggles for Sudden Motion, Bright Visuals, Reduce Switch Splashes, Common Layout, Notification Sound, Verification/Sound. Structure Builder, Visual Schedule, Event Routines, Safe Spaces, Reset Routine.

**Seizure Safe Mode** — split into Reduces / Replaces With: flashing lights → soft fades, rapid motion → slow transitions, rapid overlays → gentle overlays, intense transitions → gentle lighting, strobe-like glow effects → static aura, high-frequency animation → minimal or no animation. Visual Comfort Settings: Brightness, Contrast, Animation Intensity, Color Intensity, Motion Sensitivity. Quick Safe Presets. Flash & Particle Safety panel with per-effect controls (Aura Pulse, Sparkles, Particle Drift). "Safety is not a limitation. It is care."

**Also absent from the Blueprint:** WCAG (0), screen reader (0), colorblind (0), photosensitivity (0). The Blueprint says "accessibility" 20 times without naming a standard.

**Why this ranks first:** TruLura's entire visual identity is glow, pulse, particle drift, and screen-wide animation. A seizure-safety mode isn't a feature request — it's what makes the aesthetic shippable.

**Separate Visual Adjustments panel** (also absent): Reduced Motion, Static Moods, Soft Reactions, Minimized Effects, Sound Off.

---

## 2. Appearance & theming system

**"TRULURA APPEARANCE & MODE SYSTEM — Every atmosphere. Every emotion. Every feeling."**

Six named appearance modes, all zero in the Blueprint:
- Dark Cinematic
- Light Luxury
- Neutral
- Soft Mode
- Minimal Mode
- High Atmosphere

**Adaptive System** — adapts to Morning / Day / Evening / Night / Late Night, plus Emotional State, Battery Level, Ambient Light, Atmosphere Mode, Environments.

**Time-Adaptive Emotional Appearance** — "Living, breathing, adapting — just for you." Per-period color and energy definitions with transition speed and adaptation strength sliders.

**Adaptive Aura Color System** — named palettes: Cosmic Blue, Sunset Amber, Dream Violet, Rose Glow, Emerald Calm, Moonlight Silver, Aurora Pink, Midnight Indigo, Soft Gold, Reflective Lavender. Each with Aura Ring Color, Glow Color, Emotional Accents, Mood Lighting, Compatibility, Interactions.

**Adaptive Human Experience System** — six experience profiles: Neurodivergent Support, Sensory Comfort, Visual Accessibility, Cognitive Clarity, Motor Ease, Emotional Safety, Wellness Companion. With adaptive intelligence that "learns your patterns" and "adapts over time."

**Aura themes** (separate vocabulary): Rainlight, Glowbeam, Cosmos, Softpulse, Nebula, Aura-Cloak, Moonlight.

---

## 3. Reaction vocabulary — directly answers the label-inventory question

The screenshots show these as **visually distinct actions with distinct icons**, not one system with contextual names:

**Spark · Glow · Echo · Reflect · Relate · Uplift · Comment · Save to Memory · Send Drop · Vibe Boost · Sit With · Send Glow · Soft Reply · Support**

Each carries different iconography and appears in different contexts. Several award **Emotional XP** at different rates: "+3 Emotional XP — Offered calm support", "+15 Emotional XP", "+3 Emotional XP — You made someone feel seen".

**Codex found all of these mapping to one handler in the code.** If the screenshots represent intent, that isn't a naming problem — it's roughly a dozen unbuilt interactions sharing one implementation.

**Vent-specific response set:** Glow Hug, Vibe Bomb, Soft Echo, Silent Sit With You.

**Glow Space set:** Hug, Soul Tap, Glow Chain.

---

## 4. Tiered platform — three separate products

This is the single biggest structural finding. The screenshots show **three distinct branded builds**, not one app with age settings.

### TruLura KIDS
Own wordmark ("TRULURA KIDS"), bright/pastel palette, cartoon mascot.
- **Glow Pet** — named creature companion (Luna), About Me, Badges, "Don't forget to care for your Glow Pet"
- **Glow Game** — "Catch as many Glows as you can in 30 seconds," high score, customizable fire, Glow Buddy
- **Parental approval on every post** — "Is this post OK to share?" → parent Deny/Approve
- **Friend structure:** Close Friends, Friends at School, Online Friends, Approved Friends, Add Family
- **Safety set:** SOS, Auto-Blur, Calm Mode Timer (1hr / 2hr / no limit), Report & Block
- **Rewards:** Glow Shop, Glovenvory (stickers, backgrounds), Daily Quest, Kindness Grove, Calm Lake, Mood Ring Selector
- Categories: Animals, Science, Art, Crafts

### TruLura TEEN
- **AuraShield Lite** — reduced-capability version of the adult safety system
- **Vibe Report Card** — "Aurora's end-of-week," Bravery / Chill / Joy scored in "Auras," Kindness Points, Safe Score
- **Aura Level + Emotional XP** — Level 4, 2,650 XP, "Share positive energy to boost your Aura"
- **Vibe's Quest / GlowQuest / Buddy Quest**
- **Teen Privacy & Safety Settings:** who can message, who can view profile, Glow-only mode, Comment restrictions, Blocked profiles, Blocked words, Reported content, Time limits
- **Clubs** (Waylinders, Star Seeker), **Badges** (Kind Soul, Great Listener)
- **Safety Companion** — mascot-form check-in
- Teen actions: Kind Wave, Glow Drop, Send Vibe, Trusted Connect
- **Parental dashboard:** Mood & Content Activity graph, bullying alert detection, Aura-Shield content limiting, Restrict Chats, Limit Explore

### TruLura (adult)
Everything else in this document.

**Blueprint coverage:** the PO Decision Record notes a "separate-platform direction" for minors. The Blueprint does not contain these as designed products.

---

## 5. Alt & Intimate Mode — adult content tier

Absent from the Blueprint as a named system.

- **Enable Alt & Intimate Mode** — "Find connections that explore sensuality, desire, or luxury"
- **Interest categories:** Spark+, TruLuxe, Kink/Fetish, Sugar Dating
- **Roleplay categories:** Sensual, Dom/Sub, Exhibition, Emotional Kink, + Add Filter
- **Boundaries:** Playful Flirting, Censored Pics Only, Flirt Respectfully, Flirt Forwardly Yet Respectfully, Visible to Similar Auras
- **Consent & Safety Preferences:** I'm Open To, Hard Limits, Aftercare Needs
- **Sensitive Photo — Unlock After Chat**
- **Intimate Room Preview** with per-item consent: Praise / Roleplay / Humble, Kind Dom energy, Sensual aftercare
- **Curiosity & Compatibility Map** — sliders for Curious↔Open, Comfortable↔Serious, Power Dynamics (Submissive↔Dominant, Playful↔Serious, Gentle↔Bold), Vulnerability Comfort (Guarded↔Share All), Pillow Talk (Reflective↔Forthright)
- **Curiosity Match %** shown between profiles
- **Aura Contract:** "I won't fake flirt, fake love, or fake my aura intent."

This is a substantially developed consent framework. It needs legal review before it goes anywhere near canonical.

---

## 6. AuraShield — framework, not a toggle

Blueprint mentions AuraShield 5 times. The screenshots show a four-part system:

1. **AuraShield AI** — constant mood/language scanning, detection, warnings, mute safe-mode toggle
2. **Safe Match Verification** — AuraCheck, Vibe screening, smart warn/mutes, safe-mode
3. **Mood-Based Privacy Controls** — dynamic visibility based on aura, pause visibility/reconnects toggle
4. **Emotional Boundaries** — **Soft Block**, **Aura Timeout**, **Mood Fade reminder**, **Reflective report**

**Directly relevant to the Vent blocking question.** "Soft Block" and "Aura Timeout" are exactly the graduated, reversible, non-revealing mechanisms the Vent containment discussion was reaching for. Neither appears in the Blueprint.

**Crisis detection is also designed here** (PD-12 is currently open as "mechanism undefined"): "Detects moods: Despair, Numb, Panic → Replies blurred, Name hidden" → "It sounds like you're in distress. Would you like to talk to someone privately or journal this?" → Talk in Calm Mode / Journal Privately / Hide message. Plus a Mood Sensitivity slider.

---

## 7. Mood & identity vocabularies

Multiple non-overlapping sets appear, which is directly relevant to the vibe/temperament/mood ruling:

**Aura selection set:** Spark, Glow, Reflective, Empowered, Dreamy, Vent
**Mood set:** Healing, Reflective, Flirty, Calm, Energized
**Aura archetypes:** The Muse, The Flame, The Anchor, The Dreamer, The Healer, The Storm
**Emotional archetypes:** The Empath Dreamer, The Visionary, The Strategic Lover, The Idealistic Believer, Confident Dreamer, Magnetic Dreamer, The Architect
**Glow Core elements:** Flame, Storm, Ocean, Stone, Moon → composite results like "STORMGLOW"
**Expressive micro-tags (Public Mood Ring):** Introspective, Playful, Soft Touch, Magnetic, In My Bag, Wants Depth, Craves Eye Contact, Bold, Fearless Romantic, Trust Repair Mode, Eye Contact Please, Grieving, Make Me Laugh, Protective, "My Softness Is Earned"

**None of the archetype sets or the micro-tags appear in the Blueprint.** The micro-tags are the most distinctive thing in the screenshots — they read as genuinely unlike any other platform.

---

## 8. Progression, XP, and gamification

Entirely absent from the Blueprint (Spark XP: 0, Gifting XP: 0, Emotional XP: 0).

- **Aura Level** with named tiers — Level 4: Emotional Mirror, Level 5: Magnetic Dreamer, Level 8, Level 9
- **Growth Milestones:** 35 XP mood check-ins, 25 XP Spark reactions, 20 XP complete a vibe quest, Glow-Up
- **Emotional XP** awarded per interaction type
- **Spark XP** — shared between two people, with **Spark Milestones**: First DM, First Gift, First Vibe, First Mutual Vibe
- **Compatibility Growth** tracked over time
- **Vibe Quests / Daily Challenges / Weekly Quest:** "Start 3 new conversations +60 XP", "Drop 10 Vibes +100 XP", "Send 5 Spark Roses +150 XP", "React romantically +40 XP", "Send 1 anonymous compliment +20 XP", "Post a Vent entry or reply to one +25 XP"
- **Teams:** Spark Team, Glow Team, Dreamy Team, Vent — with Team Score and Team Aura Challenge
- **Glow Box** — reward container, "Complete all (0/6)"
- **Events:** Flirt Fest, Glow Fest, Vent Marathon, Moonlight Events
- **Badges:** Glow Giver, Spark Starter, Aura Royalty, Kind Soul, Great Listener, Kindness Giver, Vibe Curator
- **Energy Map** — visualized as a growing tree (Confidence, Curiosity)

---

## 9. Economy — gifts, boosts, subscriptions

**Gift catalog** (prices conflict between two boards — flagged):
| Gift | Board A | Board B |
|---|---|---|
| Glow Hug | 60 | 150 |
| Spark Rose | 400 | 120 |
| Aura Bomb | 500 | — |
| Mood Drop | — | 80 |
| Heartbeat Flame | — | 300 |
| Vibe Bomb | ✓ | — |
| Fire Bloom | ✓ | — |

Unlockable animated gifts: Reflective, Moon Kiss, Soul Mirror, Inner Radiance.

**Boost store:** Spark Surge (300) — featured in more Spark scrolls; Glow Halo (200) — aura ring glows brighter 24h; Vibe Spotlight (250) — prioritized feed placement for current mood; Mood Magnet (500) — increases gift chance 24h; Aura Openers — unlock animated intro moods.

**Subscription tiers — three conflicting versions across boards:**

*Version A:* Vibe Basic $0 / Spark+ $9.99 / Glow Elite $9.99 / Glow Elite $19.99
*Version B:* Free $0 / Basic+ $2.99–5.99 / VIP $6.99–9.99 / Elite $10.99–24.99 / For creators $2.5k per month
*Version C:* Basic+ $4.99 / VIP $9.99 / Free $19.99 (clearly mislabeled)

**Creator economics, also conflicting:** "85% of your earnings after platform fees" / "Keep 100% of your earnings for $299/month" / "90% earnings as Elite" / a 70%→Elite upgrade path.

**PD-07 (revenue percentages) is logged as open.** These boards contain numbers but they contradict each other, so they're proposals at best. Worth noting the *architecture* — subscription tier + creator tier + per-transaction gifting — matches Section 27's confirmed two-layer model.

**Creator Dashboard:** earnings, balance, XP, Total Coins, Withdraw/Payout, Gift Analytics, Top Fans/Top Supporters with named ranks (Dreamy Supporter, Glow Boost Giver, Spark Flame), Revenue Breakdown (Tips / Events / Subs / Star), Estimated upgrade earnings.

**Also in the analytics board:** Emotional Engagement Over Time, Audience Emotional Map, Emotional Pacing, **Revenue Protection**, **Creator Wellness** (Sleep Quality, Stress Level, Wellness Score).

---

## 10. Live & creator surfaces

- **TruLura Live / TRULURA TV** — Live Rooms, Go Live, Explore, Upcoming, viewer counts, Cosmic Quest streams
- **Vibe Arena / Host Panel** — co-hosted live with an **AI participant** (AI counselor, AI Aura) alongside human hosts; Spark % shown per participant
- **Emotional Reality Series** — named shows: REVIVAL, SECOND CHANCES, SOUL JOURNEYS, BEYOND CONNECTION, THE CIRCLE
- **Spark House** — trademarked, with waitlist, casting call, and Spark House TV
- **Creator Studio**, **Creator Live Rooms**, **Curator Panel**, **Live Match Broadcast**, **Co-Hosted Live Stream**
- **TruTV Awards**

Blueprint: Live Hub (1), TruTV (2), livestream (2). Named, not specified.

---

## 11. AI Companion

Far more developed than the Blueprint's version.

- **Named instances across boards:** Aura, Neva, Nova, Hannah, Eva
- **Appearance options:** Animated Avatar, Aura Orb, AI Pet, Ghost, Humanoid, Feline, Realistic, Sphere
- **Personality:** Empath, Motivator, Listener, Healer, Coach, Calm, Witty, Engaging, Soft
- **Voice:** Feminine / Masculine, tone selection
- **Configurable:** appearance, aura color, vibe type, voice, name
- **Companion surfaces:** Reflections, Dreams, Vent, Get Answers, Spirit Guide, Ideas, Search
- **Post-connection reflection:** "Hey Darcell, how are you feeling after that connection?" → Satisfied / Drained / Vulnerable / Warm / Conflicted → grounding activity or affirmation
- **Watches dates with you:** "Looks like they're vibing. Want to analyze it together?"
- **Companion Journey Recap** — reflections count, deep connections, vibe shifts
- **Aura Memory Timeline** — "Reliving your sparks," dated emotional events
- **Grounding Tools:** Breathing Exercise, Grounding, Calm Meditation, Body Scan, Visualization, Release
- **Aura Memory** — "Narrates growth"

Note: Section 27 confirms **no memory at launch**, Phase 2 for persistent memory. Aura Memory Timeline and Companion Journey Recap are Phase 2 features by that decision.

---

## 12. Quiz system — TruQuiz

Blueprint says "quiz" 38 times but contains no quiz catalog and zero "TruQuiz."

**Named quizzes:** Vibe Identity, Emotional Energy Rhythm, Relationship Chemistry, MBTI Personality, Attachment Style, First Spark Impression, Match Intent, Conflict Style, Communication Style, Healing Style, Vent Space Support Preference, Alt Mode Comfort & Consent, Social Energy, Companion, Aura Expression, Love Language, Childhood Lens.

**Glow Lab** — a second quiz surface, organized as GLOW CORE / SPARK CORE / IDENTITY / JOURNEY: Love Shield (+90 XP), Emotional Safety, Inner Child, Your Spark Language (+90 XP), How You Heal (+120 XP, Locked).

**Spark Language™** — trademarked, zero Blueprint mentions. Touch / Words / Gifts / Time, 4 questions, produces composite results like "Warm Glow + Quiet Spark" with trait tags (Needs reassurance, Loves presence over words, Has nurturing energy) and unlockable emoji rewards.

**Emotional Blueprint** — per-user report combining archetype, astrology (Sagittarius in Seventh house), love languages with percentages (Words 36%, Touch 26%, Time 21%, Gifts 17%), Vibe Expression, Conflict Style.

---

## 13. Sync — the actual concept

**"SYNC RESONANCE ENGINE — Express the frequency only you carry. Turn on Sync to translate your frequency into resonance with other people."**

Controls: Pacing (Flowing / Dating / Still active / Frequency ready), Activate Sync, Tune Field. "Sync is ready when you are." Emotional match preview showing shape and progression.

**This is materially different from the swipe interface currently implemented.** Other boards show "SWIPE TO CONNECT" and "THIS ISN'T SWIPING. THIS IS SOUL-SYNCING." — so the design material itself is unresolved between a swipe deck and a resonance field.

**Sync-related concepts absent from the Blueprint:**
- **Aura Link Code** — pairing two people with a **Mood Contract** (Soft Intro / Deep Convo / Quiet Presence) and Aura Tips
- **Aura-Locked Message** — "Receive when recipient is Reflective." Mood-gated delivery.
- **Attraction Layers** (2 Blueprint mentions, undeveloped)
- **Compatibility Resonance Map**, **Personality Overlays**, **Compatibility Calibration**
- **MeetPoint Discovery** — real-world meeting suggestions with safety ratings (SAFE SPOT / CHILL / POPULAR), QR check-in & confirm, conversation prompts
- **Alignment Confirm / Resonance Confirm**
- **Slow Burn Match**

---

## 14. Spaces, worlds, and circles

- **Emotional Worlds / Browse Emotional Worlds:** Tandem Spaces, Anime Worlds, Gaming Realms, Healing Circles, Creator Hubs, Emotional Communities
- **Named support rooms:** Single Moms, Breakup Healing, Overwhelmed, LGBT+ Support, Mommy Space, Anime Club
- **Glow Spaces:** "Soft Hearts Only"
- **Spark Circles**, **Glow Circles™**, **Live in These Worlds**, **Enter a World**
- **Home Feed sections:** Today's Energy, Mood Matches, Spark Circles

Blueprint has Healing Circles as a canonical-merge pointer; the code currently implements them as keyword text search.

---

## 15. Mode system

Named modes across boards, most absent from the Blueprint:
**Full Sync Mode · Cinematic Mode · Soft Mode · TruMode · Date Mode Only · TruDating · Sync Mode · Vent Space · Explore · Healing Mode · Calm Mode · Glow-only mode · Travel Mode · Gaming Mode**

Two different bottom navs appear:
- Aura / Sync / Explore / TruMessages
- Home / Glow / Spark / Vent / Profile

---

## 16. Brand system — entirely uncovered

Blueprint: wordmark 0, logo 0, tagline 0, motion language 0, brand essence 0, typography 2.

**Signature mark:** heart + infinity, with cross/star variants. Multiple explorations.
**Typography:** TruLura Display, TruLura Serif, TruLura Sans — with full specimen sheets.
**Taglines across boards:** "TRUTH · CONNECTION · SOUL" · "Truth. Connect Your Soul." · "WHERE VIBES LIVE" · "The Emotionally Intelligent Social Platform" · "More Than Social. A Deeper Connection." · "CONNECT · FEEL · GROW · BELONG"
**Five logo concepts named:** Celestial Resonance, Pure Connection, Aura Essence, Radiant Core, Sacred Geometry, Luminous Embrace.
**Color palette** with hex values: Indigo Glass `#1E293B`, Violet Aura `#7E5FEF`, `#1C2726`.
**Motion language** and **icon set** defined.

**Naming exploration** (candidate names, presumably rejected): AuraFeed, Auralign, Lumen, TruRealm, AuraCircle, AuraSignals, TrueMuse, AuroraGlow, AuraGlow, Truecho, Auraclusive, Truexclusive, Auravibe, Aurasignals.

---

## 17. Trademark list — from a Policy & Terms board

**Core Brand ™:** Spark House · Glow Circles · Vent Space · AuraShield · Spark+ · Glow Elite · TruJourney
**Sub-Brands:** Spark House · Glow Elite · TruJourney · Mood Meter · Aura Avatar

**Community Guidelines (Core Values)** — *Behavior That Sparks:* respect mood signals, consent-based connection, emotional safety in rallies/gifts/DMs. *Moderation Tools:* AuraShield reports auto-analyze mood breaches; infractions = temporary aura freeze, not just account strike; repeat harm = vibe suspension or TruLura lockout.
**Aura Violations:** aura-breaking gifts, mood baiting or faking vibe.

This is a different enforcement vocabulary than Section 27's confirmed restorative model. Worth reconciling rather than adopting.

---

## 18. Smaller items worth not losing

- **Auto-Translation with "Emotion-Preserved" toggle** — translate messages between languages while preserving emotional register. Korean / Spanish / Japanese shown. Genuinely distinctive; nothing comparable exists on other platforms.
- **Voice Drop / Voice Mood Drop / Aura Story** — audio posts with waveform
- **Spotify integration** on posts — track attached to mood
- **Aura Bell**, **Glow Journey**, **Aura Evolution**, **Memory Vault**, **Memory Timeline**
- **Waitlist mechanics** — "Your place in line: 89,753," invite link to skip spots, referral counts, feature unlock timeline
- **Launch Readiness checklist** — Profile Set Up, Aura + Mood, Vent/Match Preferences, Companion Activated, Safe Mode
- **Reflection Summary** — "Since joining, you've reflected 42 times, connected deeply 6 times, and grown through 3 vibe shifts"
- **Onboarding as 7 steps:** Quiz → Archetype → Intention → Aesthetic → Energy → Personality → Calibration

---

## Ranked recommendation

**1. Accessibility.** Three complete modes at zero Blueprint coverage, on a platform built from animated glow. This is the only item where absence creates real-world harm rather than lost differentiation.

**2. The reaction vocabulary.** It decides whether Codex's finding is a naming cleanup or a dozen unbuilt features. Cheap to resolve, and it's blocking a real engineering decision.

**3. The three-tier product structure.** Kids / Teen / Adult as separate builds is an architectural fact that changes how everything else is scoped. It intersects a confirmed PO decision (minors, separate-platform direction) and is currently undocumented.

**4. AuraShield's Soft Block and Aura Timeout.** Directly relevant to the open Vent blocking question, and more graduated than the binary block currently built.

**5. Crisis detection.** PD-12 is logged as "mechanism undefined." A designed mechanism exists in these boards. Still needs Trust & Safety review, but the design work isn't missing — it was lost.

**6. Alt & Intimate Mode.** Substantial and needs legal review before anything else happens with it.

**Do not port wholesale.** The conflicts within this material — three subscription schemes, two gift price lists, two navs, swipe vs. resonance — are evidence that these boards are different generations of thinking. Each item needs a decision, not a copy.
