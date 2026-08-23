# TruLura Permission Matrix

*Every permission-gating statement the TruLura Blueprint makes — who can post, comment, message, monetize, livestream, create communities, create events, travel, access TruLuxe, and verify — compiled from the "Permission-Gating Language" flagged lists gathered while producing `TruLura_Blueprint_Cross_Reference.md`. This is not a numeric access-control matrix, because the Blueprint itself does not contain one: it states gating **factors** (mode, trust level, verification level, age, emotional state) and qualitative **rules** ("requires," "cannot," "unlocks"), but almost never a formula for combining them. That absence is itself the Blueprint's single most-cited engineering gap (EG-01, "no formula for combining Mode + Trust Score + Verification Level + Emotional State into one access decision," home §10.5.1) and this document does not invent one to fill the gap.*

## The Four Canonical Gating Factors

Section 10.5.1 states the exact input list every access decision draws from, without giving the combining logic:

> **"Current Mode, Trust Level, Emotional State, Verification Status, Environment Context"** — §10.5.1

Section 11.3.1 (AI Decision Engine's own Decision Inputs) restates the same four-factor pattern from the AI side, adding Interaction History and Profile Attributes. Every action-specific permission below is an instance of these factors being applied to one specific capability — none of the instances below give numeric thresholds either.

## Action: Post / Comment / React

| Context | Rule | Source |
|---|---|---|
| Youth environments | No adult content exists in youth spaces (absolute) | §22.7 |
| Vent Space | No virality optimization; increased moderation sensitivity; emotion-first design (implicit posting constraint, not an access gate) | §9.8.3, §14.2 |
| Anonymous identity | Cannot access "certain private interactions" (unspecified which) | §1.1.1 (141–147) |
| Discovery/Feed content generally | Cannot bypass Trust & Safety Layer filtering "through engagement" — applies globally, cannot be overridden by activity or payment | §4.2.1 |
| Reactions/Chains | No numbered access restriction found | §4.12 |

*No numeric follower/trust threshold is stated anywhere for posting or commenting eligibility.*

## Action: Message / Communicate

| Context | Rule | Source |
|---|---|---|
| Dating-context messaging | **"Messaging within a dating context requires both users to be in a compatible mode and to have passed minimum trust thresholds"** — thresholds undefined | §6.2.1 — **canonical instance of EG-01** |
| Dating Mode (Spark/Sync) | **"Mutual Consent Required"** | §9.4.1 |
| Escalation checkpoints | Consent checkpoints required before: Messaging Escalation, Media Sharing, Location-Based Meetups, Private Sessions And Matchrooms | §9.4.2 |
| New/low-trust users | Message rate limiting applies | §9.6.1 |
| General interaction | "Restricted Interaction Access Based On Trust Level" | §9.6.1 |
| Youth environments | Youth users "Interact Only Within Controlled Environments" — no cross-environment communication with adults | §9.10.2, §9.10.1 |
| Chat UI | "Consent-based escalation" enforced in chat interaction controls | §10.14.2 |
| General | "Controlled messaging permissions → Prevents unwanted or overwhelming communication" | §25.6 |
| Background-check disclosure | "Reveal Background Checks Only In Dating Mode" | §9.2.3, §9.16.2 |

## Action: Monetize (Tip, Gift, Subscribe, Sell Access)

| Context | Rule | Source |
|---|---|---|
| Anonymous identity | Cannot access Payments / Monetization tools | §1.1.1 |
| Identity elevation | Required before: Financial actions, High-trust matchmaking, Creator monetization | §1.1.1 |
| Verification Level 2 (Verified) | "Unlocks dating, monetization, and higher-trust features" | §1.2 |
| Youth environments | Youth users "Cannot Access Monetization Systems"; "No adult content or monetization exists in youth spaces" (absolute) | §9.10.2, §22.7 |
| Vent Space | **Explicitly excluded — "No monetization prompts within sensitive discussions... No direct monetization... No ads... No paid boosts... No monetization tied to emotional vulnerability."** Exceptions "may be introduced outside of active distress states." | §14.9, §8.6.2 — **PD-13 ("strict rule... without an actual rule set")** |
| Emotional distress/vulnerability (any context) | "Monetization is suppressed during emotional distress, vulnerability, or burnout states" | §12.6, §7.6, §13.5 |
| AI-driven prompts | AI "does NOT push purchases during emotional vulnerability... does NOT upsell during distress states"; monetization guidance is "advisory only, not financial control"; "influence only, not control" | §15.10, §11.7.3, §11.12.2, §11.13 |
| Discovery/feed boosting | Boosted content must pass safety checks, match intent/mode, align emotional context; "cannot override safety, mode, or emotional alignment"; **"If content fails any of these checks, it cannot be boosted — regardless of payment or engagement level"** | §4.1.5, §4.2.6, §4.11 |
| Spark/matchmaking monetization | Stage-gated: early-stage restricted to visibility-based enhancements only; mid-stage adds communication-based enhancements; advanced stages unlock compatibility/experience/real-world tools; post-match stages allow subscriptions | §7.6, §7.12.1, §7.8.1 |
| Creator tier | Revenue percentage and tool access vary by tier (Emerging/Growing/Established/TruElite), gated on "progression level, trust status, verification status, community health metrics, compliance history, platform participation quality" — no numeric criteria given | §7.7.2, §7.7.1 |
| Platform vs. creator monetization boundary | External APIs "do not control visibility or earnings"; "Core monetization remains internal" | §21.5.2 |

*Exact revenue-split figures ARE given at §7.8 (Gifts/Tips 80–90% creator, Subscriptions 70–85%, Events 50–75%, Brand Deals 60–80%) — the only monetization figures in the Blueprint with actual numbers, not ranges tied to a formula. See PD-07/EG-08.*

## Action: Livestream / Live Events

| Context | Rule | Source |
|---|---|---|
| Live Layer (Social Ecosystem spaces) | "Enables real-time interaction such as livestreams, voice rooms, and events" — no independent access gate stated beyond the general Space State gating (below) | §19.13.1 |
| TruStudio Live Tools | Part of the Creator Dashboard's 6-tab structure; access implicitly tied to Creator role, no numeric criteria given | §13.3 |
| Youth environments | Not explicitly addressed for livestreaming specifically; inherits the general youth-environment prohibition on adult/monetized content | §22.7 (by extension, not stated for live specifically) |

*No dedicated livestream-eligibility subsection exists in the Blueprint; livestream access is inferred from Creator role + Space Live Layer + general monetization/youth rules above.*

## Action: Create Communities / Spaces

| Context | Rule | Source |
|---|---|---|
| Space State: Open | Publicly accessible with minimal restrictions | §19.13.2 |
| Space State: Restricted | **"Requires approval, eligibility, or behavior-based access"** | §19.13.2 |
| Space State: Private | Invitation-only with full privacy control | §19.13.2 |
| Space State: Premium | **Access requires subscription or payment** | §19.13.2 |
| Space Role: Host/Owner | "Controls space structure, rules, and overall direction" — the role that can effectively create/govern a space | §19.16 |
| Space Role: Moderator | "Responsible for enforcing rules and maintaining safety" | §19.16 |
| Space Role: Contributor | "Elevated role with content creation privileges" | §19.16 |
| Space Role: Member | "Standard participant with basic interaction access" | §19.16 |
| Trust-based privilege expansion | "User privileges expand based on behavior and reliability" | §19.19 |
| Quest-driven entry | "Users unlock spaces by completing actions or engagement milestones" | §19.14 |
| Vent Space membership | Access via Visibility Levels: Private (Self Only), Trusted Circle, Community Support Layer, Anonymous Community Mode | §14.4 |

*No numeric per-role permission set exists (Engineering Gap EG-23) — who is actually authorized to create a NEW Space (as opposed to holding a role within an existing one) is not explicitly stated anywhere in Sections 4.18 or 19.*

## Action: Create Events

| Context | Rule | Source |
|---|---|---|
| Event Space State | "Temporary spaces created for specific events or experiences" | §19.13.2 |
| Community World event/ritual creation | Seasonal events, community milestones, recognition programs are described as system/community features, not gated to a specific role | §4.18.5, §18.12.1 |
| Creator-hosted events | Named as a monetization stream ("Live Events, Digital Experiences") available to Creator role holders | §8.11 |
| TruTravel group experiences | Gated on the full TruTravel Eligibility Check (below) | §16.4, §16.10.1 |

*No dedicated "who may create an Event" gating subsection exists independent of the Creator/Host-role and TruTravel-eligibility rules already covered elsewhere in this matrix.*

## Action: Travel (TruTravel)

*Confirmed Phase 2 for the entire section (§16 — see `TruLura_Blueprint_Cross_Reference.md`).*

| Context | Rule | Source |
|---|---|---|
| Core philosophy | **"Safety Before Access"** — one of TruTravel's four founding principles | §16.2 — **PD-17** |
| Experience Structure Flow, Stage 3 | **"Eligibility Check"** — explicit gate requiring "Safety + compatibility verification" before Commitment Phase | §16.4 |
| Eligibility factors | Identity verification status; **"Safety score (internal)"** — a fourth, undefined trust/safety metric | §16.5 — **PD-15 direct: "adds a 'safety score (internal)' as a fourth independent reference"** |
| Travel Trust & Verification Framework | 6 additional verification-layer examples, each influencing eligibility — no numeric thresholds | §16.5.1 |
| Verified-only options | "Verified-only participation options" exist for higher-risk travel experiences | §16.5 |
| TruLuxe Travel integration | Eligibility "may depend on verification, trust, membership status, and experience requirements" | §16.8.1 |
| Emergency safety | Emergency check-ins, SOS activation, Safe Meet integrations, trusted-contact notifications available during any travel experience | §16.12.1 |

## Action: Access TruLuxe

*Confirmed Phase 2 for the entire section (§17). This is the single most permission-gated system in the Blueprint.*

| Context | Rule | Source |
|---|---|---|
| Payment alone | **"Access to TruLuxe is not guaranteed through payment alone. Even if a user subscribes, they must still meet behavioral, verification, and profile standards."** "This prevents the system from becoming a 'pay-to-access anyone' environment." | §17.2 — **PD-18 direct** |
| Application/Waitlist pathway | Review process evaluates "profile quality, intent, behavioral signals" | §17.3 |
| Invitation-Based pathway | "Existing qualified users or the system itself may invite users." | §17.3 |
| Eligibility Through Behavior pathway | Merit-based: "positive interaction history, respectful communication, consistent engagement patterns" — explicitly "not just a financial one" | §17.3 |
| Revocation | If a user "violates safety standards, shows manipulative behavior, degrades interaction quality — they can be removed from TruLuxe" | §17.3 |
| Overall participation requirement | **"Participation requires: verification, behavioral trust, eligibility approval."** | §17.7.1 |
| Payment vs. conditionality | "Users pay for access to the TruLuxe environment, but access is still conditional." | §17.9 |
| Anti-purchase-of-people clause | **"TruLuxe does not allow users to pay for access to other individuals."** — the clearest single anti-discrimination statement in the Blueprint | §17.14 — **PD-18 direct** |
| Interaction standard | "All interactions remain: Consent-based, compatibility-driven, behavior-qualified." | §17.14 |
| High-Trust Verification tiers | 6 named verification tiers (Identity/Profession/Creator/Travel/Meet/TruLuxe Verified) — no combining formula given | §17.11.1 — **PD-15 direct, compounds the four-way naming conflict** |

## Action: Verify (Identity, Trust, Background)

| Level | Requirement | Unlocks | Source |
|---|---|---|---|
| **Level 0 — Basic** | Email or phone verification | Limited access | §1.2 |
| **Level 1 — Standard** | Selfie verification | "Messaging and basic interactions" | §1.2 |
| **Level 2 — Verified** | Government ID | "Dating, monetization, and higher-trust features" | §1.2 |
| **Level 3 — Trusted** | Optional background check | "High-trust badge and premium access credibility" | §1.2 |

**No numeric matrix exists mapping each level to every gated feature** — this is Engineering Gap EG-07 directly, confirmed at every subsection that references a verification level throughout Sections 1–22.

**Verification is named independently under at least three other schemes, unreconciled to the above four levels:**
- §2.1.2: Unverified → Basic Verified → Advanced Verified → Elite Verified
- §9.2.1/§9.2.2: Basic Account Validation, Identity Verification, Behavioral Verification, Social Proof Layer, Background Check Layer → composite Trust Levels (Unverified, Partially Verified, Verified, High-Trust/Trusted, Restricted/Flagged)
- §16.5: adds "Safety score (internal)" as a fourth independent reference (per PD-15)
- §17.11.1: 6 further named tiers (Identity/Profession/Creator/Travel/Meet/TruLuxe Verified)

**PD-01/PD-15 track this four-(or more)-way naming conflict as unresolved. This matrix does not merge or rank the schemes — see `docs/02-Product/Glossary.md`'s Trust Score entry for the full citation set.**

## Cross-Cutting Principles (Apply to Every Action Above)

Stated once, in general terms, and implicitly governing every row in this matrix:

- **"Permissions are not globally granted. They depend on the user's state. Two users may have completely different permissions at the same time based on trust, mode, and behavior."** — §10.5
- **"Behavioral permissions, discovery visibility, monetization access, and interaction capabilities are governed independently within each environment. User behavior in one environment does not automatically transfer unrestricted access into another environment."** — §9.10.1
- **"Trust Score Impact: Feature access / Visibility / Interaction permissions / Monetization eligibility."** — §22.18.2
- **"High Trust → expanded capabilities, streamlined workflows, reduced friction."** / **"Restricted State → limited actions with transparent explanations and restoration guidance."** — §20.4
- **"Users are never penalized for reduced participation caused by limited social energy."** — §20.13.5, §25.4.1 (an explicit anti-gating guarantee, not a restriction)
- **"External systems must never override Trulura's internal governance, safety layers, or trust systems."** — §21.1; **"External APIs do not control visibility or earnings."** — §21.5.2; **"Verification providers generate signals only — final decisions remain internal."** — §21.3.2
- **"Tiered admin roles / Limited access based on function... No individual should have unrestricted system access."** — §24.4 (administrative/internal access, no numeric tiers given)
- **"System Override... used only in: Security threats / System failures / Legal or compliance risks."** — §24.5

## Not Yet Defined

- The combining formula for Mode + Trust Level + Verification Status + Emotional State + Environment Context into a single access decision (EG-01, canonical home §10.5.1) — every action-specific rule in this matrix is an instance of this same missing formula.
- The numeric permission matrix mapping each of the four Verification Levels to every gated feature (EG-07).
- Who, specifically, is authorized to create a new Community World/Space (as distinct from holding a role within an existing one).
- A dedicated livestream-eligibility rule set independent of general Creator-role and youth/monetization rules.
- Whether the additional trust/verification schemes named at §2.1.2, §9.2.1/9.2.2, §16.5, and §17.11.1 are meant to be the same concept as the canonical Section 1.2/1.3 scheme, partially overlapping, or genuinely independent (PD-01/PD-15).

## Cross-References

`docs/03-Architecture/TruLura_Blueprint_Cross_Reference.md` (source of every citation) · `docs/02-Product/Glossary.md` (Trust Score, Safety Score, Verification Levels entries) · `docs/02-Product/TruLura_Product-Decisions.md.md` (PD-01, PD-13, PD-15, PD-17, PD-18) · `docs/02-Product/TruLura_Engineering-Gap-Register.md.md` (EG-01, EG-07, EG-23).
