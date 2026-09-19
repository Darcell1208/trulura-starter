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

## Open — not decided by DR-EXP-1: what the sender sees

When a report holds a message past its stated expiry, the sender's view is
undecided. The Product Owner has explicitly declined to rule on it pending
options, and it is recorded here so it is not settled by implementation
default.

The tension: **any per-message signal that differs from "it vanished" is
evidence that a report exists.** In a one-to-one conversation there is exactly
one other participant, so "a report exists" identifies the reporter with
certainty. That is the retaliation case reporting exists to protect against.
In a group conversation the same signal is far weaker.

This must be decided before the client change ships, because shipping either
behaviour decides it silently.

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
