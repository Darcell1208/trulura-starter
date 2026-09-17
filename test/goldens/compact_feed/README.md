> **These goldens are not evidence.** Read this before trusting a pass.
>
> - `ring.png` and `dot.png` were regenerated with `--update-goldens` on
>   2026-09-14 at 02:38 UTC, one minute after the suite failed against them
>   (`ring.png`: 1.74%, 4339px) because a coloured dot had been added to the
>   mood chip. `moods.png` was created with `--update-goldens` at 02:37 UTC and
>   rewritten the same way at 03:02 UTC. Claude did all three, in a Claude Code
>   session, and said so at the time. Nobody reviewed the images.
> - They record what the widget drew at that moment, not what it should draw.
>   `moods.png` includes an untagged card whose chip reads "Radiant", a label
>   invented by `_vibeLabelFor` (Build Status known issue 24).
> - They render `CompactFeedCardPresentation` on its own, with fixture data.
>   On 2026-09-14 this suite passed 9/9 while the running app was drawing a
>   different card entirely (known issue 23). A pass shows the widget still
>   paints the same pixels. It does not show the design is right, or that the
>   app is using this widget.
>
> Before any of these images is used to accept or reject a change, compare it
> with an approved design and replace this note with who approved it and when.
> The `../feed_boundary` baselines are a different kind of golden; see their
> README. Build Status known issue 26 records the same facts.

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
