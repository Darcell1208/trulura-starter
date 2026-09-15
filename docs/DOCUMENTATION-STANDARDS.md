# TruLura Documentation Standards

Standards for how decisions and project state are written down in this
repository. Each one says who set it and why, so it can be read, questioned
and changed in the open.

Standards 1 and 2 were set on 2026-09-14. They were briefly kept only in an AI
session's private memory, and moved here on the Product Owner's instruction:

> "Session memory isn't auditable and doesn't survive. Put them where anyone can read and disagree with them."

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

---

## 3. Decision state is lettered; failure classes are named

**Set by:** Darcell (Product Owner), 2026-09-14.

**The standard.** Two classification schemes are in use, and they share no
symbol.

- **Decision state, how settled a decision is, keeps its letters, A to D.**
  - **C:** open; needs the Product Owner's ruling.
  - **D:** a fresh Product Owner decision, recorded with a verbatim quote.
  - **A and B** are used as already defined in the Product Owner's tracker.
    They are not defined in this repository, and are not reconstructed from
    usage.
- **Failure classes, the shape of a bug, have no letters.** Use the name:
  - device-global state where account-scoped was required
  - swallowed write reporting success
  - default counted as an answer
  - one word naming several concepts
  - several words naming one concept
  - one concept reading another's storage
  - duplicate implementation
  - invented number
  - verification producing false confidence

**Why.** The two scales shared one alphabet, so a letter from the wrong scale
could not be detected by inspection. The 2026-09-14 decision record used
"Class D" both for a fresh decision and for a default counted as an answer.
That is the failure the disjoint-vocabulary rule
(`TruLura_PO_Decision_Vibe_And_Temperament.md`, Ruling 2 of 2026-09-13) exists
to prevent, applied to the project's own metadata.

**Sweep, 2026-09-14.** Lettered failure classes in the records were replaced
by their names. One use was left as written because its meaning cannot be
determined from context: "Class-B-adjacent" in
`TruLura_PO_Decision_Record_2026-09-14.md`.

---

## 4. Decisions live in the decision records; open questions live in the register

**Set by:** Darcell (Product Owner), 2026-09-14. Ruling: "the PO decision
records win."

**The standard.**

- **Decisions that have been made** are recorded in
  `docs/TruLura_PO_Decision_*.md`, including the dated
  `docs/TruLura_PO_Decision_Record_2026-09-14.md`. That is the canonical
  location.
- **Open product questions** live in the Product Decisions Register,
  `docs/02-Product/TruLura_Product-Decisions.md`, until the Product Owner
  rules. The ruling is then recorded in a decision record, and the register
  entry points at it rather than restating it.

**The stated reason was corrected the same day.** The ruling was first given
on the premise that the `02-Product` register had never held anything. It
holds 21 live open product questions, PD-01 to PD-21; what it has never held is
a decision. The empty file was `TruLura_Product_Decision_Log.md`, which is not
the register. With the premise corrected, the Product Owner kept the ruling in
the split form above. Guiding Principles #10 was corrected to match in `3e19271`. The Documentation
Constitution was corrected in the same commit, then archived later that day
from its original text (DR-5); the current Constitution,
`docs/01-Constitution/05-TruLura_Constitution.md`, states the rule in
section 1.
