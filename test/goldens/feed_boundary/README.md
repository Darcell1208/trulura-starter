# Feed card presentation boundary verification

The 24 PNG baselines were captured on 2026-09-13 from the existing working
copy BEFORE changing production code for spec injection, and reproduced in a
second run before the refactor. Both runs used the same Windows machine and
SDK executable path: C:/Users/darcl/flutter/flutter/bin/cache/flutter_tools.snapshot
(via that SDK's dart.exe). Existing uncommitted work was part of the baseline.
Today's zero-tolerance 48/48 rerun certifies that the recorded toolchain matches
the original baselines, regardless of which toolchain captured them.

## Isolation verification, 2026-09-17 (corrects commit 9119cb2)

The message on commit 9119cb2 states that its contents "have not been tested
in isolation" from the then-uncommitted Home wiring. That was accurate when
the message was written and is no longer accurate. A pushed commit message
cannot be corrected without rewriting history, so the later result is recorded
here, next to the baselines it concerns, rather than only in the commit log.

On 2026-09-17 commit 9119cb2 was checked out into a separate git worktree
holding that commit and nothing after it. The absence of the later WIP layer
was asserted rather than assumed: in that tree home_feed_screen.dart contained
no reference to CompactFeedCardPresentation, chat_list_screen.dart none to
profileImageProvider, and home_hub_screen.dart none to the HomeHubScreen.build
debug print. There `flutter analyze` reported no issues, and
compact_feed_card_test, compact_feed_mood_harness_test,
feed_card_boundary_golden_test and console_regressions_test ran 59 tests, all
passing, none skipped — the same counts as the original run. The commit
therefore compiles and its suites pass with the Home wiring absent.

Two limits on that claim. vent_known_row_trace_test contributed nothing: all
5 of its tests skip unless VENT_TRACE_BODY, VENT_TRACE_ID and VENT_TRACE_SUB
are set, so it is a committed harness rather than coverage. And this remains
component-level verification; nothing in that commit has been exercised
through the running app.

## Baseline recapture, 2026-09-17 — 17 images replaced deliberately

**This is the one sanctioned recapture of these baselines, and it is not an
acceptance of a redesign.** Read this before concluding the rule below was
broken.

`_vibeLabelFor` was deleted on 2026-09-17 (Build Status known issue 24). It
hashed the author's display name into one of eight invented labels, and the
legacy `FeedCard` header pill rendered that hash for every non-anonymous post.
The pill now shows `post.moodTag` when there is one and nothing at all when
there is not. **The legacy pill never read `post.moodTag` at any point before
this**, so for Vent and Profile cards this is the first time these images show
a real mood rather than a fabricated one. That is why the baselines moved: the
data in them changed from invented to true. Composition, geometry, type and
colour were not touched.

**Measured before regenerating, not after.** SHA256 of all 28 images was
recorded before any code change and compared afterwards. 18 changed, 10 did
not, and `git status` listed exactly the same 18:

- **Changed (17 here):** the 16 `profile_*` and `profile_boosted_*` baselines,
  plus `positive_accent_green.png` — that last one is a post-boundary
  known-positive reference, non-anonymous with `moodTag: 'reflective'`, so its
  pill text changed along with the rest. It is easy to overlook when counting
  "the 16 baselines"; it is included here.
- **Unchanged, confirmed per file rather than assumed (8 here):** every
  `vent_*` baseline is byte-identical. The Vent fixtures are anonymous, the
  pill is suppressed for anonymous posts (`feed_card.dart`, the
  `!isAnonymous` guard on the header pill), so nothing in them could move.
- Also unchanged outside this directory: `../compact_feed/ring.png` and
  `dot.png`, whose fixtures all carry mood tags.

**What this does not license.** The rule below stands unchanged: these
baselines must never be refreshed to accept a visual redesign. The test for a
future recapture is the one applied here — name the specific data or toolchain
fact that changed, measure the blast radius before touching anything, confirm
the images that should not move are byte-identical, and record all of it in
this file. A recapture that cannot state which images moved and why is the
`--update-goldens`-after-failure pattern that Build Status known issue 26
exists to record.

## Baseline recapture, 2026-09-19 — one image, `positive_accent_green.png`

A second sanctioned recapture, and a far smaller one. `_PostPresenceStrip` is
now suppressed when glow, react and share counts are all zero (Build Status
known issue 29), which removed the strip from the only fixture whose counts
resemble live data.

**Measured before regenerating, per the standard below.** The suite ran first
without `--update-goldens`: `+24 -1`, with all 25 tests reaching `tearDownAll`
so the count is real rather than an early abort, and
`positive_accent_green.png` the single failure. After regenerating,
`git status` listed exactly one modified image. The 24 pre-change baselines are
untouched — confirmed by git, not assumed.

**Why only one moved, and why that is itself a finding.** The shared fixture
sets `likeCount: 7, shareCount: 2` (`:243-244`), so `total` is 9 and the strip
still renders in all 24. Only `positive_accent_green`, built separately with no
counts (`:70-80`), behaves like production — where all 12 posts have zero rows
in `post_reactions`. A change that removes an element from **every card in the
running app** surfaced here as a single image. The prediction made from these
fixtures was wrong by a factor of seventeen. That fixture-validity problem is
Build Status known issue 34.

**This does not license refreshing the 24.** They stay as they are, and the
standard in the 2026-09-17 note applies unchanged.

## Baseline recapture, 2026-09-19 (second today) — all 28 images

The largest recapture so far, and **the first time the 24 pre-change baselines
have moved.** Authorised explicitly. `shareCount` was removed from the strip and
from `Post` (Build Status known issue 33), and the shared fixture's invented
`likeCount: 7, shareCount: 2` was zeroed (known issue 34).

**Why they moved, and why this is still not a redesign.** Removing `shareCount`
forced the fixture change — `shareCount: 2` no longer compiles. With the
fixture's invented counts gone, `total` is 0 on every card, so
`_PostPresenceStrip` is suppressed exactly as it is in the running app. The
images changed because the fixtures stopped describing a world that does not
exist: the data in them moved toward production, not the design away from it.

**Measured before regenerating.** Run without `--update-goldens` first:
`+31 ~5 -28`. Every one of the 28 failures was confirmed to be a golden
mismatch and nothing else, by listing all 28 failing test names — 8 of them
surfaced through a `throwsNothing` wrapper (`Expected: null / Actual:
FlutterError:<Golden ...>`) rather than a "Pixel test failed" line, and could
otherwise have hidden a real regression behind a regeneration.

**A measurement trap worth recording.** That pre-regeneration run named only
the frame-`_0` images. The `_300` frames were **not** unaffected: each test
compares at frame 0, then pumps to 300ms and compares again, so a failure at
frame 0 aborts the test before the second comparison ever runs. Those images
were *unmeasured*, not unchanged — `git status` after regenerating showed all
of them moved. **A failing golden suite under-reports its own blast radius**;
only the filesystem gives the true scope.

**Scope, confirmed by git rather than asserted:** exactly 28 modified images —
the 24 baselines, `positive_accent_green.png`, and the three `../compact_feed`
images.

**Attribution caveat — these images carry two sessions' changes, not one.** A
concurrent session's tap-to-open-full-post feature (an `InkWell` +
`showDialog` wrapping the compact preview, in
`lib/widgets/compact_feed_card_presentation.dart`) was already in the working
tree when this blast radius was measured and regenerated. The three
`../compact_feed` images therefore reflect **both** that feature and the share
action losing its count; they cannot be attributed to the `shareCount` removal
alone. The 24 boundary baselines render `FeedCard` directly and are not
affected by that feature, so those are attributable to the fixture change. If a
future reader is bisecting a compact-card difference to this date, look for two
causes, not one.

**The rule still stands.** These baselines are not to be refreshed to accept a
visual redesign. This recapture qualifies under the standard set in the
2026-09-17 note: a specific data fact changed, the blast radius was measured
first, the scope was confirmed by git, and it is recorded here.

## Valid toolchain

- Flutter 3.44.0 stable, framework 559ffa3f75e7402d65a8def9c28389a9b2e6fe42
- Engine 4c525dac5ebe5971c5708ef73558ed8edcf4a362
- Dart 3.12.0
- Windows x64; reported OS version 10.0.26200.0

These baselines are valid only for this toolchain/platform and the local font
fixtures below. A toolchain/platform change requires deliberate baseline
recapture and review; it is not a validation pass against the original baseline.
Preserve the original baseline and its provenance when creating a new one.

Run from the repository root:

    flutter test --no-pub test/feed_card_boundary_golden_test.dart

Do not use --update-goldens to validate this refactor. Flutter's default local
golden comparator compares decoded pixels with zero tolerance.
baseline_sha256.json records pre-change source and PNG hashes. The PNG hashes
were checked separately to confirm that reference images were not replaced;
the widget test itself does not enforce that hash manifest.

## What the tests establish

Card-component goldens exercise the shared renderer for anonymous Vent, named
Profile, and boosted/video-preview fixtures; 300px and 640px widths; light and
dark application themes; frame zero and 300ms. Omitted specs and explicitly
supplied fromPost specs use the same original baselines: 24 tests and 48
exact-pixel comparisons.

Spec injection drives card appearance now; it is not reserved for later plumbing.

The original injection assertions check object identity and widget-tree text.
The added test `accent injection paints the border without changing text` tests
paint directly, through the same shared renderer:

- Render the default, then inject a spec changing ONLY accentB to #00FF00.
  Geometry, labels, seed, and animation phase remain identical.
- Read actual RGBA pixels. In the straight top-border scanline (excluding rounded
  corners and text), require more than 400 samples, over 90% with summed RGB
  change >= 30, and mean increase in green-minus-blue greater than 20/255.
  A one-pixel difference, text-only change, or arbitrary color change cannot pass.
- For author name and post body, require identical screen rectangles and exact
  foreground RGBA pixels painted by the actual laid-out RenderParagraph objects.
  The paragraphs are painted onto transparency for this check: the aura behind
  text intentionally changes, so composited text rectangles are NOT claimed to
  remain identical. This checks text paint and layout, not merely Text properties.
- Compare the injected card against positive_accent_green.png, a NEW post-boundary
  golden; it is a known-positive appearance reference, not a pre-change baseline.
- Remove the injected spec on the same state and require the entire card's RGBA
  pixels to equal the initial default exactly.

The targeted control run replacing the injected accent with the original accent
must fail the border-change assertion; this validates sensitivity to a no-op.
The original 24 pre-change PNGs remain untouched. The suite now has 25 tests:
48 original-baseline comparisons plus one new positive golden and regional/raw
pixel assertions. The positive fixture uses 640px, dark theme, DPR 1, frame zero;
accentB is paint-verified end to end through the border path; the remaining
spec fields are verified as forwarded via object identity, with label use
checked in the widget tree, not individually verified as painted. The fields
share the injected spec object but have distinct consumers (layout, transforms,
backgrounds, and painters), so this is not a claim of one common paint/apply path.
The refactor targeted the presentation boundary, not a change to any specific
visual field; accentB is the representative probe that the boundary reaches paint.
The avatar halo is mode-palette-driven and is not the region under test.

## Explicit exclusions

- Full Vent/Profile screen rendering is NOT exercised. These are card goldens.
- DPR above 1, including DPR 2 and 3.
- Short viewports and short-viewport overflow: height is fixed at 1500.
- Timestamp branches other than 'just now': a future fixture date pins that text.
- Live backend/auth state, remote images, and all possible posts or interactions.
- Other toolchains/platforms and different font files.

Post identity, content, fonts, and animation pump durations are fixed. The
anonymous fixture contains an inline User, but the anonymous rendering path
suppresses that identity; this is not a null-user fixture. The earlier Vent
overflow issue is not ruled out by these component goldens.

## File integrity, separate from rendering coverage

Vent and Profile screen files retained their pre-refactor SHA256 hashes when
checked. This proves only that those files were unedited. Their shared renderer
changed, so unchanged screen-file hashes do not establish unchanged screen pixels.

## Font source of truth

Use the checked-in local fixtures, not a fresh download:

- ../../fixtures/fonts/SpaceGrotesk.ttf
- ../../fixtures/fonts/Inter.ttf

font_sha256.json pins their bytes. OFL license files accompany the fonts.
The test asset handler supplies these variable fonts for requested family weights;
production font loading is unchanged. Changing either fixture's bytes changes
the test environment and requires deliberate baseline recapture and review.

Provenance only (moving upstream URLs, NOT reproducible re-fetch instructions):
- https://raw.githubusercontent.com/google/fonts/main/ofl/spacegrotesk/SpaceGrotesk%5Bwght%5D.ttf
- https://raw.githubusercontent.com/google/fonts/main/ofl/inter/Inter%5Bopsz,wght%5D.ttf

The local copies were downloaded on 2026-09-13.
