# TruLura Decision Record — Ephemeral expiry and the report hold

Class D — Product Owner decision. The ruling is quoted verbatim; explanatory
notes below a quote are Claude's and are not part of the decision.

---

## DR-EXP-1 — Reported content is held

**Product Owner, verbatim, 2026-09-19:**

> "Reported content is held.
>
> Expiry deletes for everyone else; a report places a hold and the content is
> retained until review closes. The schema already takes this position — it
> prevents deleting reported messages — so expiry is what has to accommodate
> it, not the reverse.
>
> One requirement that comes with it: the UI must say so. If a setting promises
> disappearance and reporting quietly preserves it, that's a broken promise made
> silently. Whatever the control says should state both halves — disappears for
> everyone, retained if reported until review closes."

*Note (Claude):* the schema position referred to is real and predates this
ruling. `20260908_reports_targets_and_status.sql` leaves
`reports.target_message_id` at `ON DELETE NO ACTION`, so a reported message
cannot be hard-deleted while its report stands. Build Status known issue 35
records the operational consequence: an unheld purge does not skip the held row
and delete the rest, it raises a foreign key violation and aborts, so one held
message would disable expiry for everyone. The hold is therefore required for
the purge to work at all, not only as policy.

**Mapping to the schema.** `reports_status_enum` allows `queued`, `reviewing`,
`actionTaken`, `dismissed`. This record reads "review closes" as:

| Status | Meaning here |
|---|---|
| `queued` | Open — hold |
| `reviewing` | Open — hold |
| `actionTaken` | Closed — release |
| `dismissed` | Closed — release |

A held message is not deleted at the moment its review closes; it is deleted on
the next sweep after closure, since its expiry is already past. A message held
through review is therefore retained slightly longer than its stated TTL.

**State when this was ruled, measured against the live database 2026-09-19:**
nothing expires at all. `public.messages` has no `expires_at` column; the client
computes an expiry but never sends it; `pg_cron` is not installed; there are no
triggers on `messages` and no routine matching `expir`. The control promises
disappearance and no mechanism of any kind exists behind it.

---

## DR-EXP-2 — What the sender sees during a hold

**Product Owner, verbatim, 2026-09-19:**

> "Sender visibility: E with D's modifier.
>
> - Control copy states the exception in advance: messages disappear, unless
>   reported, in which case they're held until review closes.
> - During a hold the message is hidden from the sender, retained server-side.
>   No per-message signal.
> - Review closes with no action: silent deletion.
> - Action taken: the sender learns through enforcement.
>
> Not C — in a 1:1 thread it identifies the reporter with certainty, which is a
> cost paid by the person who reported."

*Note (Claude):* the decisive objection to C is that the cost falls on the
reporter rather than on the reported. In a one-to-one conversation there is
exactly one other participant, so "a report exists" and "you reported me" are
the same statement.

**Why this is implementable honestly, established 2026-09-19.** The sender's
device retains no copy of a remote message. `ChatService.getMessagesByChatId`
early-returns to `_getRemoteMessagesByChatId` whenever Supabase is ready
(`chat_service.dart:580-583`); every local `setString` touching messages sits
in a path the remote branch never reaches — the local-stub branches
(`:606`, `:666`, `:846`), `_initSampleData`'s demo seeding (`:479`, `:529`),
and a one-time legacy local-store migration (`:163`, `:174`).

That matters to the choice. Hiding a message that still exists **on the
device** would be a claim about the user's own storage that is false. Hiding a
message that exists only on the server, after the control has already disclosed
the exception, is suppression of a retained record — a different and smaller
claim. Had a local copy existed, E would have needed re-examination.

**What the implementation must therefore do**, and what it must not:

- The client filters expired messages out of the sender's view on read. It does
  **not** claim the row is gone.
- No per-message badge, tooltip, timestamp anomaly or ordering gap may reveal
  that a particular message was held. Any such signal reintroduces C's cost.
- Silent deletion on close-with-no-action is the purge's existing behaviour: a
  held message is deleted on the first sweep after its report closes, because
  its expiry is already past. No extra code is needed for that half.
- Disclosure on action taken belongs to the enforcement path, which does not
  exist yet. Until it does, the "action taken" half of this ruling is unbuilt,
  and that should not be described as implemented.

---

## DR-EXP-3 — Releasing the hold when a report closes

**Product Owner, verbatim, 2026-09-19:**

> "Ruling: option four. Cascade the report, write a contentless durable record
> to moderation_events first — that a report existed, against whom, and how it
> closed. No content retained anywhere.
>
> One addition: capture the author on the report at file time in its own
> column, populated from messages.sender_id. Not a target, so it doesn't
> collide with reports_exactly_one_target. Without it the durable record can't
> name who was reported.
>
> No snapshotting. It turns a bounded hold into indefinite retention of the
> content we promised would vanish, in a table with no expiry of its own."

*Note (Claude):* implemented in
`supabase/migrations/20260919b_report_cascade_with_durable_record.sql`, applied
2026-09-19.

**Why CASCADE is acceptable now when 2026-09-08 rejected it.** That migration's
objection was that CASCADE "would destroy the report when the reported content
is deleted, which is exactly when the report matters most." That held while
nothing survived the deletion. The `record_report_removal` trigger now writes a
contentless record *before* the report row goes, so what survives is the fact of
the report, whom it named, its reason and how it closed — everything except the
content the user was promised would disappear.

**A safety net was removed, and that is worth stating plainly.** Before this,
an expiry sweep that wrongly targeted a held message failed loudly on the
foreign key and deleted nothing. With CASCADE it would instead delete the
message *and* silently cascade away its open report. The purge predicate is now
the only thing standing between an open report and its evidence, which is why it
is verified directly rather than assumed — see the hold probe under known issue
35.

**Verified end to end, 2026-09-19**, in rolled-back transactions against the
live database:

- A report inserted against a real message came back with
  `target_message_author_id` equal to that message's `sender_id`, with the
  insert supplying no author — so the trigger populates it, not the caller.
- With the report `dismissed`, the purge deleted the message (`purged=1`), the
  report cascaded away, and `moderation_events` gained exactly one contentless
  row: `report_removed:dismissed || reason=other report_id=… had_message_target=true`.
- With reports `queued`, `reviewing`, and an open report on the *conversation*,
  the purge deleted nothing (`purged=0`), all three messages survived, and no
  durable record was written.

---

## Closed — the local-copy question that preceded DR-EXP-2

**Question:** does the sender's device retain a copy of a remote message? The
Product Owner required this closed *before* ruling on sender visibility, on the
grounds that hiding a message that still sits on the user's own device is a
different and larger dishonesty than hiding one that exists only on the server.

**Answer, established 2026-09-19: no.** In remote mode nothing about a message
is written to the device.

- `ChatService.getMessagesByChatId` early-returns to
  `_getRemoteMessagesByChatId` whenever Supabase is ready
  (`chat_service.dart:580-583`). The local branch below it is unreachable in
  remote mode.
- Every `setString` in `chat_service.dart` that touches messages sits in a path
  the remote branch never reaches: the local-stub read and send (`:606`,
  `:666`), the chat list (`:846`), `_initSampleData`'s demo seeding (`:479`,
  `:529`), and a one-time legacy local-store migration (`:163`, `:174`). That
  last one migrates pre-existing local data between keys; it never caches a
  remote row.

**Consequence for DR-EXP-2.** Server-side deletion is real deletion — there is
no second copy to outlive it. Hiding a held message from the sender is
therefore suppression of a record that exists only on the server, after the
control copy has already disclosed that exception, rather than a false claim
about the user's own storage. Had a local copy existed, option E would have
needed re-examination before being ruled.

**If this ever changes** — if offline caching or local message persistence is
added to the remote path — DR-EXP-2 must be revisited, because its honesty
argument rests on this finding and not on the ruling itself.

---

## Sequencing required by this record

The UI copy required by DR-EXP-1 must not ship before expiry actually works.
Stating "disappears for everyone, retained if reported until review closes"
while nothing expires would replace a vague false promise with a precise one.
Product Owner, 2026-09-19: "Agreed on UI copy — it lands with steps 1 and 2. A
precise false promise is worse than a vague one."

1. Apply `20260919_message_expiry_with_report_hold.sql` (adds `expires_at`,
   adds the held purge function). Requires database admin.
2. Schedule `purge_expired_messages()`. `pg_cron` is not installed; enabling it
   or standing up a scheduled Edge Function requires database admin. Until a
   schedule exists the function is correct and never runs.
3. Ship the client change that sends `expires_at` on insert and filters expired
   rows on read — only after step 1, or sends fail on an unknown column.
4. Ship the UI copy stating both halves.
