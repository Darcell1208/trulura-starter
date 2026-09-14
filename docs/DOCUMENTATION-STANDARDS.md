# TruLura Documentation Standards

Standards for how decisions and project state are written down in this
repository. Each one says who set it and why, so it can be read, questioned
and changed in the open.

The first two were set on 2026-09-14. They were briefly kept only in an AI
session's private memory, and moved here on the Product Owner's instruction:

> "Session memory isn't auditable and doesn't survive. Put them where anyone can read and disagree with them."

> **Not yet in this file: the class definitions.** The decision records and the
> build status page use lettered classes, but no document in this repository
> defines them. The letters are also used for two different things:
>
> - **How settled something is** — for example "Class C — design material,
>   not decided product" and "Class D — fresh Product Owner decisions"
>   (`TruLura_PO_Decision_Record_2026-09-14.md`, line 3).
> - **The shape of a bug** — for example "failure class A: device-global where
>   account-scoped was required" (`TruLura_Build_Status.md`) and
>   "Class D (default counted as an answer)" in the same decision record.
>
> So "Class D" currently means a fresh decision in one sentence and a default
> counted as an answer in another. The definitions belong here, next to these
> standards, once the Product Owner supplies them; they are not reconstructed
> from usage.

---

## 1. Commit a recorded decision when it is written

**Set by:** Darcell (Product Owner), 2026-09-14.

**The standard.** When a Product Owner ruling is written into a decision
record, commit and push it as part of the same piece of work. It is not left
as a local edit to be tidied up later.

- If the record also holds older uncommitted text that the new entry depends
  on, commit them together, and say so in the commit message. Do not leave a
  new ruling pointing at text that is not on the remote.
- The usual commit checks still apply. Check the staged files against an
  expected list, check that no proposal rides along, and verify the result
  from the fetched remote after pushing.

**Why.** On 2026-09-14 four rulings had been written into the records and left
uncommitted. In the Product Owner's words, they "are the whole point of the
records existing, and leaving them local repeats the drift you just fixed twice
today." The same day, a decision record and a design brief had disappeared from
a project folder, and the database schema had moved ahead of code that existed
only in an unpushed working tree. A record that exists on one machine protects
nobody else.

---

## 2. One canonical home for each kind of document

**Set by:** Darcell (Product Owner), 2026-09-14.

**The standard.** A kind of document has one home. Before creating a folder
or a document in `docs/`, check whether that kind of content already has one:
the numbered folders `01-Constitution` to `09-Archive`, the top-level Product
Owner decision records, and `TruLura_Build_Status.md`.

- If a requested location would create a second home, name the existing one
  first, and let the Product Owner choose which is canonical.
- When duplication is found, consolidate it straight away with pure renames
  (`git mv`, checked as 100% renames) so history is kept.

**Why.** Two homes for the same kind of document means "whichever someone opens
becomes the truth." That is the failure behind two Blueprints and two decision
records. On 2026-09-14 a new `docs/design/` folder was created beside the
existing `docs/06-Design/`. The Product Owner chose `docs/06-Design/`, and the
folders were merged "while it's two files rather than twenty."
