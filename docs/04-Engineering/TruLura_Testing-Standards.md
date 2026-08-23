# TruLura Testing Standards

*Current state, documented honestly, plus what will eventually belong here — not an invented testing strategy. No test framework decision, coverage target, or CI process is specified below beyond what already exists in the repository, because none currently does.*

## Current State

The `test/` directory contains zero files. `flutter_test` is a listed dev dependency in `pubspec.yaml` but nothing in the repository uses it (Technical Debt TD-17, confirmed directly: `find test -type f` returns nothing). Every provider, service, and screen in the app is currently unverified by any automated test.

## What Will Eventually Belong Here

When test work begins (Engineering Backlog ENG-017), this document should record, as they're actually decided — not before:

- Which testing types are adopted (Flutter's own conventions offer unit, widget, and integration tests as standard categories — which of these the team actually uses, and in what proportion, is Not Yet Defined)
- Coverage expectations or targets, if any are set
- Which modules are tested first (the Engineering Backlog recommends characterization tests for the identity-merge logic in `AppProvider`/`UserService` and the router's redirect logic, since those are the areas already slated for the Sprint 1 refactors in ADR-001/ADR-002 — testing before refactoring, not after)
- Any CI/CD test-gating process, once one exists

## Not Yet Defined

Test framework choices beyond `flutter_test` (already a dependency, unused), mocking strategy, golden-file/snapshot testing, coverage tooling, and CI integration are all undecided. None are invented here.

## Cross-References

`docs/04-Engineering/TruLura_Systems_And_Debt_Review.md` TD-17 · `docs/04-Engineering/TruLura_Engineering-Backlog.md` ENG-017 · `docs/05-Development/README.md` (development workflow, once populated).
