# TruLura build handoff — October 9, 2026

This checkpoint records current PO direction and implemented scope. It supplements existing product records; it is not a replacement master or a claim that recovery/reconciliation is complete.

## Current direction

- Social platform first; dating optional.
- Birthday required. The existing build currently collects an integer age; birthday collection/migration remains work.
- ID verification is for adults accessing strictly 18+ areas, including dating and TruLuxe. No teen ID requirement was approved.
- Alt/dom/fantasy belongs inside dating and inherits the adult boundary. This placement does not approve every historical Alt feature or content/monetization proposal.
- Teen Vent must be separate from adult Vent. Failure of an adult verification check never establishes teen eligibility.
- Earlier blanket verification-before-any-Vent interpretation is superseded. The external recovery SQL candidate still contains that obsolete assumption and must not be deployed.
- ID-provider choice is deferred until closer to completion. Continue independent build work; do not add simulated verification to production or treat local flags as provider proof.
- Mommy Space, dad/men's support, It Takes a Village and family-support material remain preserved. Separating children's accounts into a future platform does not remove parent-facing support. Feature-by-feature reconciliation remains necessary.

## Implemented and pushed

| Commit | Scope |
| --- | --- |
| 162bf40 | Account basics/age gates; optional dating defaults; adult mode protections; profile save failure handling; stale-account guards; verification scaffolding restrictions; Vent save fixes; applied feed-permission migration record. |
| 0f0cc15 | Alt/Intimate settings nested under Dating; screen test. |
| a59862f | Adult content checks before author override; signed-out and unverified viewers denied by app filter. |
| bab608e | Adult content cannot bypass permitted feed contexts through ownership. |
| 453290d | Followers/unknown privacy denied to nonowners by app filter. Follower graph authorization remains absent. |
| 614e041 | Missing/unrecognized privacy defaults to private in post read/save normalization. |

These are app/repository changes unless explicitly described below. They are not a completed server authorization implementation. Alt remains a separate internal mode; nesting its settings card is not full navigation/content integration. Existing verification-level enums and debug simulation remain scaffolding, not an operational ID integration.

## Live Supabase evidence

Owner ran feed permission repair and returned posts_feed, vent_feed and profiles_public with can_read=true/can_write=false. SQL is recorded in supabase/migrations/20261008_feed_readonly_permissions.sql. No other new live migration is confirmed in this checkpoint. CLI migration-history reconciliation was not performed.

Exported schema confirms Vent category separation but no teen/adult post group or trusted age record in inspected tables. Public profile view lacks a privacy filter. Inspected messaging function/policies and table triggers do not enforce blocks. Comment/reaction ownership alone does not enforce parent-post visibility or teen/adult boundaries. These remain backend tasks.

## Validation

74 selected regression tests passed for 162bf40; subsequent settings screen test passed; 12 adult-post tests passed, including expanded containment assertions; 18 combined privacy/adult tests passed; 8 related save/privacy tests passed after 614e041. Counts overlap and must not be added as a unique test total. These use local/mocked backends, not live multi-account probes.

Dart analysis remains inconclusive because the analyzer crashes on shutdown deleting a local performance file. Successful Flutter tests do not establish a clean whole-project analyzer result, full application build, or production end-to-end verification.

## Next implementation batches

1. Finish dating/Alt opt-in and navigation integration across controller, feed selection, composer and direct paths; preserve separate consent settings and adult eligibility.
2. Implement birthday collection and reviewed corrections, then separate account age classification from adult ID verification. Provider-independent UI may proceed; no invented provider success.
3. Rework and stage-test Vent database separation under the corrected policy, including legacy-post treatment, interaction identity, account changes, age-up and storage/share paths. Do not deploy a draft that silently hides all existing Vent content.
4. Implement server-side adult content restrictions, bilateral messaging blocks and profile visibility. Test alternate APIs, not only visible screens.
5. Resume onboarding, Sync/Vent feature and visual reconciliation against accepted mockups; verify dead controls, media persistence/reels/video, then confirmed monetization implementation. Money policy and full recovery artifacts remain in the chat recovery workspace; they have not all been copied or implemented in this repository.

No source exports, personal chat transcripts, credential files or unapproved SQL drafts are included in this GitHub checkpoint. Future claims of completion must distinguish source recovery, PO confirmation, code implementation, database deployment and observed behavior.
