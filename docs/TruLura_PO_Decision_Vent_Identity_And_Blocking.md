# TruLura Product Owner Decision Record — Vent Identity, Replies & Blocking

**Decision date:** 2026-09-09
**Decided by:** Darcell (Product Owner)
**Classification: mixed — see each entry.** Decisions 1 and 4 are *recorded
restatements* of positions the Blueprint already commits to; they are written
here only so nobody re-opens them. Decisions 2 and 3 are **Product Owner
Decisions, 2026** on questions the Blueprint does not address at all. That
distinction is load-bearing and follows the provenance discipline set by the
Aura architecture record — do not let it blur.

---

## Verification note (2026-09-09)

Every Blueprint citation below was read directly from
`docs/02-Product/TruLura_Blueprint.md.md` at the line numbers given, not
recalled. Two negative findings were established by exhaustive search of the
20,344-line document and of `docs/` as a whole, and they are what make
decisions 2 and 3 decisions rather than recoveries:

- **"pseudonym" appears zero times** in the Blueprint and zero times anywhere
  in `docs/`. The Blueprint has no concept of a pseudonym and does not
  distinguish anonymity from pseudonymity.
- **"non-transferable" appears zero times.** §1.5.2 does not define protected
  participation as non-transferable, so nothing there rules out a
  consent-based identity reveal.

---

## 1. Replies to a Vent post stay inside the post, both sides anonymous

**No DM channel.** A reader can respond to a vent only within that vent.

**Rests on** — this is already the Blueprint's written model, not a new
decision:

> **§14.4 Visibility & Privacy Controls** — "**Anonymous Community Mode** —
> Identity is hidden while still allowing interaction."

> **§14.5 Interaction Model (Non-Traditional Engagement)** — interaction types
> are "Support reactions (non-quantified)", "Guided responses… structured
> replies that promote empathy and understanding", "No visible like counts or
> popularity ranking."

Recorded because the question was re-opened once and cost a Blueprint read to
settle. It is settled.

---

## 2. Per-post pseudonyms, for thread readability only — not per-user

Anonymous posts display a stable-looking name generated **from the post**, not
from the person. A thread stays coherent; nothing links a name across posts.

**Classification: Product Owner Decision, 2026.** The Blueprint is silent on
anonymous *presentation* — it has no pseudonym concept at all (see verification
note). This is authored here.

**Rests on:**

> **§1.1 Identity Core System** — "Each user has one master identity. That
> identity can branch into contextual layers: Social identity, Dating identity,
> Creator identity, **Anonymous identity**, Luxe identity… These are **not
> separate accounts**. They are **contextual expressions of the same identity
> system**."

> **§1.1.1** — "Sensitive states (e.g., anonymous or protected environments)
> **may require revalidation**."

A persistent per-user handle that people recognise and accumulate impressions
of is a second account in everything but storage — a thing reputations attach
to, that can be followed, recognised, and harassed as. That is the outcome §1.1
forecloses. Per-post naming gives readable threads without creating a second
identity.

**The cost, accepted deliberately:** per-post names cannot be blocked, which is
what decision 3 exists to resolve. A per-post name is a label, not a person.

### 2a. Amendment, 2026-09-09 — comments derive from `post_id` + `user_id`

**Recorded before comments exist. Do not build from this; build the feature
first, then apply this rule.**

Decision 2 as shipped derives the name from the post id alone, which is correct
for posts and **breaks for comments**. A comment is a separate row with its own
id, so the shipped scheme would give one commenter a different name on every
reply — and an unreadable thread is the exact failure per-post names were
introduced to fix.

The rule for comments is to derive from **the post id and the commenter's user
id combined**:

- Same person, same thread → the same name throughout.
- Same person, a different vent → an unrelated name.
- Nothing links a person across posts, which is what decision 2 protects.

This applies to the vent's author as well, using their own user id with their
own post id, so the author reads consistently inside their own thread.

**Accepted consequence:** within one thread it becomes possible to tell that two
comments came from the same person. That is the readability the names exist
for, and it does not extend beyond the thread.

**Open question, not decided:** should the vent's author be visually
distinguished from commenters inside their own thread? Distinguishing them
makes the conversation easier to follow and tells readers which name belongs to
the author, which is a small disclosure. Not distinguishing them makes the
author read as one participant among several. This needs deciding before
comments ship, because it is not a late styling choice — it determines whether
the author's name carries meaning.

### 2b. BLOCKING prerequisite — `comments` RLS would defeat all of this

Verified against the live database on 2026-09-09, and it contradicts the
assumption that comments do not exist at all:

- `public.comments` **does exist** — columns `id`, `post_id`, `user_id`, `body`,
  `created_at`. RLS is on and it has four policies. It holds **zero rows**.
- What does not exist is the app side: no comment service, no model, no query.
  The UI shows a snackbar reading `Comment sent (stub)`
  (`lib/widgets/feed_card.dart:624`) and writes nothing — the same
  no-write-confirmation class as the other stubs on the placeholder inventory.
- `authenticated` holds both SELECT and INSERT on the table.
- **`comments_select_authenticated` is `USING (true)`** *(as of 2026-09-09 —
  closed 2026-09-14, see the update at the end of this section)*. Any signed-in user can
  read every comment row, `user_id` and `post_id` included. There is no view
  nulling the author the way `vent_feed` does for posts.

So if comments are built on this table as it stands, the pseudonym is
decorative for exactly the reason open item B describes for blocks: the client
can compute what the interface hides. A comment on an anonymous vent ships the
commenter's real uuid to every authenticated client, and if the **author**
comments on their own vent, `comments.user_id` joined to `comments.post_id`
deanonymises the vent itself — through a plain client-runnable query, with no
exploit involved.

Nothing leaks today because the table is empty. The first comment ever written
would be exposed. **This is read off the policy definition, not demonstrated
with data** — no probe row was written to production to prove it.

Before comments ship, `comments` needs the same treatment posts already have: a
view that nulls `user_id` for comments on anonymous posts, with the raw table
kept out of the client's reach, exactly as `vent_feed` does. The derivation
rule above is worthless without it.

**Update 2026-09-14 — the open read is closed; the view is still owed.**

- **What changed:** `comments_select_authenticated` was dropped and replaced
  with `comments_select_own` (`user_id = auth.uid()`), and `anon` lost every
  privilege on the table. Live migration
  `20260914133748 comments_select_own_only`
  (`supabase/migrations/20260914_comments_select_own_only.sql`). It was
  applied while the table held 0 rows, so no comment was ever exposed.
- **Verified by role against the applied change** (probe rows rolled back):
  - an author reads, edits and deletes their own comment;
  - another signed-in user reads 0 rows, including when filtering by the
    author's `user_id`, and their update or delete by id affects 0 rows;
  - an insert carrying someone else's `user_id` is rejected by RLS;
  - `anon` is denied both read and insert.
- **What this does not do:** it does not provide the read path described
  above. Before comments ship, other people's comments still have to come
  through a view that nulls `user_id` on anonymous posts.
- **A conflict that view has to settle first:**
  - **2a:** derives a commenter's name from post id + user id. If the view
    nulls `user_id`, the client cannot derive it.
  - **A plain hash of the two ids will not do:** every profile id is readable
    through `profiles_public`, so the hash can be reversed by trying each one.
  - **So:** the name, or a token for it, has to be produced server-side.

---

## 3. Blocks resolve on `posts.user_id`, never on the displayed name

**Classification: Product Owner Decision, 2026.** Implementation position; the
Blueprint does not address it.

`posts.user_id` holds the real author even when `is_anonymous` is true — the
row always carries it, and only the view nulls it. Verified in the live view
definitions on 2026-09-09: both `vent_feed` and `posts_feed` select
`CASE WHEN is_anonymous THEN NULL::uuid ELSE user_id END AS user_id`.

So a block placed on an anonymous author resolves to the real uuid without the
interface ever revealing it. Anonymity is a **presentation** choice, not a
storage one.

**The consequence, accepted deliberately:** the system knows what the user does
not. Someone blocking an anonymous account may be blocking a person they know,
and will not be told. That is the correct behaviour and it is also an
information asymmetry — it must never be surfaced, logged, or exposed through
any client-runnable query. **This has not yet been tested by role.** See open
item B.

---

## 4. Blocks are unified across contexts — NOT Vent-scoped

A block applies everywhere. The earlier Vent-scoped proposal is **withdrawn**.

**Rests on:**

> **§1.1.4 Multi-State Identity System, System Behavior** — "Identity states
> may vary by environment. Trust remains **unified across states**. **Safety
> systems remain unified across states**. **Platform accountability remains
> unified across states**. Users maintain one master identity."

A block is a safety system. Vent-scoping it would have contradicted a written
commitment rather than filled a gap — which is precisely the kind of move that
requires a decision record overriding the Blueprint, and the reasoning did not
justify one. Withdrawing it also removes the "a harasser must be blocked twice"
cost that scoping would have introduced.

**The cost, accepted knowingly:** a unified block propagates from Vent into the
main feed, so in principle a blocker can learn who vented by noticing who
disappeared. Whether that is actually observable is open item A, and it was the
sole argument for scoping.

---

## Open items

### A. Can a unified block be made invisible to the blocker? — investigated, not decided

If the main feed were chronological and exhaustive, a propagating block would
reveal the vent author by their absence, and decision 4 would need a record
overriding §1.1.4. The feed was inspected on 2026-09-09 (read-only):

- **`posts_feed` has no `ORDER BY`.** Ordering comes entirely from the client.
- **`PostService.fetchAuraFeed` orders `created_at DESC`** and applies **no
  `.limit()` and no `.range()`** — the fetch is chronological and complete.
- **`FeedDistributionEngine.rank` then fully re-sorts by score**
  (`scored.sort((a, b) => b.score.compareTo(a.score))`), so render order bears
  no relation to time. It also injects deliberate randomness — a jitter term
  and an `rng` seeded from `behavior.lastSignalAt`.
- **It is not exhaustive at scale.** A per-author cap
  (`lerpDouble(7, 3, feedDiscoveryBalance)`, so 3–7) skips further posts by a
  saturated author once `scored.length > 16`. The only recovery path is gated
  on `out.length < min(10, scored.length)`, so with ten or more items in the
  output those posts are dropped for good.
- **There is no pagination.** `rank()` returns the entire feed for a tab in one
  render; no `loadMore`, `nextPage`, `hasMore`, or `range` exists anywhere in
  the feed path.

**So: ranked, and non-exhaustive at scale.** A user could not reliably tell an
algorithmic omission from a block.

**Two caveats that stop this being a finished answer.** First, the drop is
latent, not active: the cap is guarded by `scored.length > 16`, and the table
currently holds one public non-Vent post, so *today the feed is exhaustive and
a block would be conspicuous*. The invisibility is a property of scale the app
has not reached. Second, the code comment at the cap reads "Delay saturated
creators rather than removing them" — that is **false**. `continue` skips the
post, and with no later page there is nothing to delay to. The comment should
not be relied on by anyone re-reading this decision.

Left open deliberately: whether "invisible once the feed is busy enough" is an
acceptable basis for decision 4, or whether the current small-scale visibility
needs handling, is a Product Owner call and is not made here.

### B. `blocks` — schema unverified, and the disclosure test not run

Two things must happen before decision 3 is called implemented, and neither has
been done:

1. **Read the live `blocks` schema before proposing any change to it.** It has
   not been inspected. It may already carry a usable column. Do not write a
   migration against assumed structure.
2. **Test the disclosure by role, not by reading.** The question is not whether
   a query "looks safe" — it is whether `authenticated` can read
   `blocks.blocked_user_id` for a Vent block and join it back to the vent. If
   they can, the anonymity is decorative, because the client can compute what
   the UI hides. This requires `set local role authenticated` with the relevant
   `request.jwt.claims`, exercised against the live database.

### C. "Certain private interactions" (§1.1.1) is undefined — BLOCKING

> **§1.1.1 Restriction Logic** — "Anonymous identity **cannot access**:
> Payments · Monetization tools · **Certain private interactions**"

Already flagged at `docs/03-Architecture/TruLura_Permission_Matrix.md:19` as
"(unspecified which)". This is the clause an anonymous DM channel would collide
with, and it is why decision 1 could be recorded as settled while a DM channel
could not simply be ruled out on its own terms. Section 14 contains no
vocabulary for DM, private message, contact, reveal, or unmask — searched in
full — so the Blueprint neither authorises nor forbids such a channel; it only
restricts it by a phrase it never defines.

**Needs its own PD entry defining the term.** Until then, any feature touching
private interaction from an anonymous state is blocked on an undefined
restriction.

---

## What this record does not decide

- Whether anonymity is permanent or session-scoped. The Blueprint does not say.
  "Contextual expression" (§1.1) plus "may require revalidation" (§1.1.1) point
  toward context-scoped, but this is inference, not a written commitment.
- Consent-based identity reveal. Not ruled out by §1.5.2 — "non-transferable"
  appears nowhere — and not written anywhere either. Genuinely open.
