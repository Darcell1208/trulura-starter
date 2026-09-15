# TruLura Constitution

*Current governing principles. Adopted 2026-09-14 by Product Owner ruling (DR-5 in `docs/TruLura_PO_Decision_Record_2026-09-14.md`). It replaces the Documentation Constitution, which is preserved unchanged as a historical record at `docs/09-Archive/TruLura_Documentation_Constitution_pre-2026-09-14_HISTORICAL.md`.*

Every statement below names the document in this repository that grounds it. A principle that could not be confirmed was left out, not softened.

## Scope

This document holds durable governing principles only:

- Product Owner authority
- the difference between evidence and decisions
- the separation of product from build
- semantic integrity
- verification discipline
- accessibility equivalence

It does not hold current bugs, implementation state, feature specifications or temporary HOLDs. The failure this scope exists to prevent is accretion into a second Blueprint. (DR-5.)

## 1. Product Owner authority

- **Decisions live in the Product Owner decision records,** `docs/TruLura_PO_Decision_*.md`, with the Product Owner's words quoted verbatim. Open product questions live in the Product Decisions Register, `docs/02-Product/TruLura_Product-Decisions.md`, until ruled; the ruling is then recorded in a decision record, and the register entry points at it. (`docs/DOCUMENTATION-STANDARDS.md`, standard 4.)
- **Decision records and the Blueprint:** "Decision records supersede the Blueprint only on the specific points they explicitly name; the Blueprint remains authoritative everywhere a later applicable decision record does not supersede it. Related concepts are not implicitly superseded." (DR-4.)
- **Decision state is lettered.** C is open and needs the Product Owner's ruling; D is a fresh Product Owner decision with a verbatim quote. (Standard 3.)
- **Authority order among the governing documents,** as stated in `docs/README.md`, naming only the documents that exist. When they conflict, the higher one takes precedence.
  1. Product Constitution: `docs/01-Constitution/01-TruLura_Product_Constitution.md`
  2. Engineering Constitution: `docs/01-Constitution/02-TruLura_Engineering_Constitution.md`
  3. Repository Architecture: `docs/03-Architecture/TruLura_Repository-Architecture.md`

  `docs/README.md` also names "Product Knowledge System", "Engineering Standards" and "Development Playbook". No document by those names exists, so they are not listed.

## 2. Evidence is not a decision

- **Design material is evidence, not decided product.** Boards, screenshots and extracted concepts carry no decision until a Product Owner decision says so (`docs/06-Design/TruLura_Screenshot_Extraction.md`), and every study frame is a noncanonical artefact (`docs/06-Design/studies/README.md`).
- **In a decision record, only the quoted Product Owner words are the decision.** Explanatory notes below a quote are not part of it. (`docs/TruLura_PO_Decision_Record_2026-09-14.md`, header.)
- **Historical material can support a decision but cannot authorize one.** (`docs/TruLura_PO_Decision_Aura_Architecture.md`, classification.)

## 3. Product is separate from build

- **The Blueprint is the specification;** `docs/TruLura_Build_Status.md` is "a status page, not a spec". (Build Status, header.)
- **Product decisions are recorded in the decision records,** not in status pages or code. (Standard 4.)

## 4. Semantic integrity

- **Vocabularies for distinct concepts must be disjoint,** because "a value in the wrong column cannot be detected by inspection, and an invariant you cannot verify is not one." (`docs/TruLura_PO_Decision_Vibe_And_Temperament.md`, Ruling 2.)
- **No concept reads another concept's storage,** even as a fallback, even when column names differ. (Same record, Ruling 3.)
- **The rule applies to the project's own metadata.** Decision state and failure classes share no symbol; failure classes are named, not lettered. (Standard 3.)

## 5. Verification discipline

- **A verified claim names how it was checked.** (`docs/TruLura_Build_Status.md`, header.)
- **Source, not compiled output, is where intent is checked.** A diagnosis from a compiled bundle stays inferred until "the corresponding source and its comments have been read". (`docs/TruLura_PO_Decision_Record_2026-09-14.md`, incident update.)
- **Report what was seen, not that something looks compliant.** (`docs/06-Design/TruLura_Study05_Brief.md`, section 5.)
- **A pushed change is verified from the fetched remote.** (Standard 1.)
- **Verification that produces false confidence is itself a failure.** (Standard 3.)

## 6. Accessibility equivalence

**The principle:** TruLura's identity must survive reduced motion and reduced effects, not degrade with them. (DR-5.)

**The test.** Show someone who knows the product a screen at its default, then the same screen at reduced motion, static Aura and minimal effects, and ask whether it is the same product. "Yes, quieter" passes. "It's the same but with everything turned off" fails. Keeping every function does not pass the test on its own. (`docs/06-Design/TruLura_Study05_Brief.md`, section 6, test 3.)

**Worked example: Study 05 Frame C, 2026-09-14.** Frame C was Home at reduced motion, static Aura and minimal effects, and the brief named this failure mode in advance (section 4). The Product Owner reported that it failed the test: "the reduced-effects frame preserved function but read as the default with the life turned off." The frames are `docs/06-Design/studies/TruLura_Study05_Home_ABC.png` and `docs/06-Design/studies/TruLura_Study05_IdentityBeyondEffects_NoNoncanonicalMark.png`. No study record in the brief's form exists, so the result is recorded as the Product Owner's report in DR-5.

**This worked example is a failure, and it stays one until a redesign earns a pass.** (DR-5.)

## Changing this document

Changes to this document are Product Owner decisions, recorded in a decision record (standard 4), and stay within the scope above. A statement whose grounding can no longer be confirmed is removed, not softened. (DR-5.)
