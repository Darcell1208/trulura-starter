> **These goldens are not evidence of design correctness.** Read this before
> trusting a pass.
>
> **Regenerated 2026-09-17, deliberately — not the pattern recorded below.**
> All three images were rewritten with `--update-goldens` after the Product
> Owner confirmed the DR-2 mood palette and directed that it be applied to the
> chip dot. The distinction from 2026-09-14 is the whole point:
>
> - The change that invalidated them was **decided first and intentional**. It
>   was not discovered by a failing test and then accepted to make the test go
>   away.
> - The blast radius was **measured before** regenerating, not assumed. Only
>   these three moved: `moods.png` by 0.06% / 265px, `ring.png` and `dot.png`
>   by 0.30% / 760px each. The 24 pre-change baselines in `../feed_boundary`
>   still pass at zero tolerance (48 comparisons), and
>   `console_regressions_test` passes.
> - The dot colours **no longer rest on these images at all.** The harness now
>   asserts each dot's RGB against `MoodPalette` and asserts the five are
>   distinct from one another. A regenerated golden can no longer hide a
>   palette collapse the way the 2026-09-14 images did — that is what makes
>   this regeneration safe, rather than the intent behind it. Build Status
>   known issue 25.
>
> **The 2026-09-14 regeneration, kept because it is the record:**
>
> - `ring.png` and `dot.png` were regenerated with `--update-goldens` on
>   2026-09-14 at 02:38 UTC, one minute after the suite failed against them
>   (`ring.png`: 1.74%, 4339px) because a coloured dot had been added to the
>   mood chip. `moods.png` was created with `--update-goldens` at 02:37 UTC and
>   rewritten the same way at 03:02 UTC. Claude did all three, in a Claude Code
>   session, and said so at the time. Nobody reviewed the images.
>
> **Second regeneration later on 2026-09-17: the invented label is gone.**
> `moods.png` was regenerated again (0.27% / 1104px) after `_vibeLabelFor` was
> deleted, on Product Owner instruction. The untagged card now renders **no
> chip at all** rather than a pill reading an invented mood — an absent mood is
> shown as absent. `ring.png` and `dot.png` did **not** move this time,
> confirmed by SHA256 against their pre-change bytes: all three of their
> fixtures carry real mood tags, so their chips were already truthful. Build
> Status known issue 24.
>
> **Still unverified after the 2026-09-17 regenerations:**
>
> - Everything in these images except the dot colours and the presence or
>   absence of the chip. Layout, type, spacing and composition have never been
>   compared against an approved design.
> - They render `CompactFeedCardPresentation` on its own, with fixture data.
>   On 2026-09-14 this suite passed 9/9 while the running app was drawing a
>   different card entirely (known issue 23, since diagnosed as a stale dev
>   build serving the legacy card). A pass shows the widget still paints the
>   same pixels. It does not show the design is right, or that the app is
>   using this widget.
>
> Before any of these images is used to accept or reject a *design*, compare it
> with an approved design and record who approved it and when. The
> `../feed_boundary` baselines are a different kind of golden; see their
> README. Build Status known issues 25 and 26 record these facts.

# Compact Home card verification

Home injects CompactFeedCardPresentation via FeedCardVisualSpec. The default
presentation remains the original FeedCard tree. Header sizes and preview lines
are constructor parameters; section composition and single-row actions are owned
by the injected presentation. Width and feed spacing remain with the screen.

The selected treatment is a 40px avatar with a 2px ring. ring.png and dot.png
show the alternatives on the same three fixture posts at 390px. Font and icon
fixtures are loaded before layout. Both use the injected accentB for the mood
indicator and pill; the mode palette does not determine the indicator color.

Run:

    flutter test --no-pub test/compact_feed_card_test.dart test/feed_card_boundary_golden_test.dart

Compact tests cover ring/dot goldens, actual ring-color RGB samples for three
people in the same Aura mode, fixed height across short/long posts, two-line
ellipsis, one-row actions, and profile/menu/four action callback forwarding.
Widths: 240, 280, 320, 390, 430 logical pixels; DPR 1, 2, 3 across these fixtures;
one 320px case at 1.5 text scale. Callback probes use test handlers; actual service
and backend behavior are retained, not newly implemented or backend-tested here.
At normal text size the card is 164px tall. Text scaling can increase its height.

No media panel, presence strip, Connect row, or promotion badge is rendered by
this presentation. Existing overflow/profile/reaction/comment/share handlers stay
in FeedCard; their existing stubs or backend limitations are unchanged.

Original Vent/Profile component goldens remain in ../feed_boundary and must
never be updated to accept a Home redesign. This is component verification, not
full-screen or live-backend coverage. Use the pinned toolchain documented there.

MaterialIcons fixtures and license come from Flutter 3.44.0's local
bin/cache/artifacts/material_fonts. The remaining pinned fonts and licenses are
in test/fixtures/fonts. No network font loading is used by these tests.
