import 'package:flutter/material.dart';
import 'package:trulura/widgets/trulura_feed_components.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_primary_button.dart';

class TruluraPostComposer extends StatelessWidget {
  final TextEditingController contentController;
  final TextEditingController captionController;
  final String postType;
  final String format;
  final String privacy;
  final String? selectedMood;
  final bool isAnonymous;
  final bool isPosting;
  final bool mediaStubAttached;
  final String textTemplate;
  final String textStyle;
  final String textBackground;
  final String? errorText;
  final List<String> moods;
  final ValueChanged<String> onPostTypeChanged;
  final ValueChanged<String> onFormatChanged;
  final ValueChanged<String> onPrivacyChanged;
  final ValueChanged<String> onTemplateChanged;
  final ValueChanged<String> onTextStyleChanged;
  final ValueChanged<String> onTextBackgroundChanged;
  final ValueChanged<String?> onMoodChanged;
  final ValueChanged<bool> onAnonymousChanged;
  final VoidCallback onToggleMediaStub;
  final VoidCallback? onSubmit;
  final VoidCallback onContentChanged;

  const TruluraPostComposer({
    super.key,
    required this.contentController,
    required this.captionController,
    required this.postType,
    required this.format,
    required this.privacy,
    required this.selectedMood,
    required this.isAnonymous,
    required this.isPosting,
    required this.mediaStubAttached,
    required this.textTemplate,
    required this.textStyle,
    required this.textBackground,
    required this.errorText,
    required this.moods,
    required this.onPostTypeChanged,
    required this.onFormatChanged,
    required this.onPrivacyChanged,
    required this.onTemplateChanged,
    required this.onTextStyleChanged,
    required this.onTextBackgroundChanged,
    required this.onMoodChanged,
    required this.onAnonymousChanged,
    required this.onToggleMediaStub,
    required this.onSubmit,
    required this.onContentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
                child: _OptionChip(
                    label: 'Public',
                    selected: postType == 'Public',
                    onTap: () => onPostTypeChanged('Public'))),
            const SizedBox(width: 8),
            Expanded(
                child: _OptionChip(
                    label: 'Mood',
                    selected: postType == 'Mood',
                    onTap: () => onPostTypeChanged('Mood'))),
            const SizedBox(width: 8),
            Expanded(
                child: _OptionChip(
                    label: 'Vent',
                    selected: postType == 'Vent',
                    onTap: () => onPostTypeChanged('Vent'))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _OptionChip(
                    label: 'Text',
                    selected: format == 'Text',
                    onTap: () => onFormatChanged('Text'))),
            const SizedBox(width: 8),
            Expanded(
                child: _OptionChip(
                    label: 'Image',
                    selected: format == 'Image',
                    onTap: () => onFormatChanged('Image'))),
            const SizedBox(width: 8),
            Expanded(
                child: _OptionChip(
                    label: 'Video',
                    selected: format == 'Video',
                    onTap: () => onFormatChanged('Video'))),
          ],
        ),
        const SizedBox(height: 20),
        if (format == 'Text')
          TextField(
            controller: contentController,
            onChanged: (_) => onContentChanged(),
            decoration: InputDecoration(
              hintText: postType == 'Vent'
                  ? 'Share your thoughts anonymously...'
                  : 'Write the text post you want people to feel',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
            ),
            maxLines: 8,
          )
        else ...[
          TextField(
            controller: captionController,
            onChanged: (_) => onContentChanged(),
            decoration: InputDecoration(
              hintText: format == 'Image'
                  ? 'Add a caption for your image post'
                  : 'Add a caption for your video post',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          TruLuraGlassCard(
            radius: 18,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                TruLuraIcon(
                  glyph: format == 'Video'
                      ? TruLuraGlyph.video
                      : TruLuraGlyph.image,
                  size: 20,
                  active: true,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mediaStubAttached
                        ? '$format attachment ready for your aura draft'
                        : 'Media upload scaffold only for now',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: isPosting ? null : onToggleMediaStub,
                  child: Text(mediaStubAttached ? 'Remove' : 'Stage'),
                ),
              ],
            ),
          ),
        ],
        if (errorText != null) ...[
          const SizedBox(height: 10),
          Text(
            errorText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
        if (format == 'Text') ...[
          const SizedBox(height: 20),
          _SectionLabel('Template'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final template in const ['Freeform', 'Quote', 'Statement'])
                TruluraFeedChip(
                  label: template,
                  selected: textTemplate == template,
                  onTap: () => onTemplateChanged(template),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionLabel('Text style'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final style in const ['Serif', 'Glow', 'Editorial'])
                TruluraFeedChip(
                  label: style,
                  selected: textStyle == style,
                  onTap: () => onTextStyleChanged(style),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionLabel('Background'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final hex in const [
                '#1A1B3F',
                '#2A153F',
                '#173033',
                '#3A1D24'
              ])
                _ColorSwatch(
                  hex: hex,
                  selected: textBackground == hex,
                  onTap: () => onTextBackgroundChanged(hex),
                ),
            ],
          ),
        ],
        const SizedBox(height: 22),
        _SectionLabel('Post Mood'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mood in moods)
              TruluraFeedChip(
                label: mood,
                selected: selectedMood == mood,
                onTap: () => onMoodChanged(selectedMood == mood ? null : mood),
              ),
          ],
        ),
        const SizedBox(height: 22),
        DropdownButtonFormField<String>(
          initialValue: privacy,
          decoration: InputDecoration(
            labelText: 'Privacy',
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: TruLuraIcon(glyph: TruLuraGlyph.lock, size: 20),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          items: ['Public', 'Friends', 'Private']
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: isPosting
              ? null
              : (value) {
                  if (value != null) onPrivacyChanged(value);
                },
        ),
        if (postType != 'Vent') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: isAnonymous,
                onChanged: isPosting
                    ? null
                    : (value) => onAnonymousChanged(value ?? false),
              ),
              Text('Post anonymously',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
        const SizedBox(height: 28),
        TruLuraPrimaryButton(
          onPressed: isPosting ? null : onSubmit,
          child: isPosting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Post'),
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? cs.onPrimary : cs.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String hex;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Color(int.parse('0xFF${hex.substring(1)}')),
          shape: BoxShape.circle,
          border: Border.all(
            color:
                selected ? Colors.white : Colors.white.withValues(alpha: 0.18),
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}
