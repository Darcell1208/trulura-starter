# Feed card presentation boundary verification

The 24 PNG baselines were captured on 2026-09-13 from the existing working
copy BEFORE changing production code for spec injection, and reproduced in a
second run before the refactor. Both runs used the same Windows machine and
SDK executable path: C:/Users/darcl/flutter/flutter/bin/cache/flutter_tools.snapshot
(via that SDK's dart.exe). Existing uncommitted work was part of the baseline.
Today's zero-tolerance 48/48 rerun certifies that the recorded toolchain matches
the original baselines, regardless of which toolchain captured them.

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
