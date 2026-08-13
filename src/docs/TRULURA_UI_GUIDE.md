# Trulura UI Design Rules (Dev Guide)

- Overall vibe: soft, emotional, social, not corporate.
- Default background: dark, gradient-leaning, with glowing accents.
- Key modes:
  - Spark = romantic / flirty, pink-peach accents.
  - Glow = kids/teens/friendship, green accents, soft and playful.
  - Vent = emotional support, blue accents, calming.

## Components

- Use `<ScreenContainer mood="spark" | "glow" | "vent" | "default">` for all screens.
- Use `<AuraHeader>` for top titles, not plain `<Text>`.
- Use `<TruCard>` for panels, forms, and info blocks.
- Use `<TruButton>` instead of plain `<Button>`.
- Use `<VibeSelector>` for vibe choices where possible.
- Use `<SparkGlowTag>` when showing the current interaction mode.

## Layout

- Rounded corners (radius.lg or radius.xl) for cards and modals.
- Bubble/chat shapes for prompts and emotional content.
- Avoid sharp corners and harsh white backgrounds.

## Copy Tone

- First-person, gentle, validating, not clinical.
- Short prompts like:
  - "Let’s set your vibe."
  - "How do you want people to feel around you?"
  - "This is how you show up today."

When creating new screens, follow these rules and reuse components.
