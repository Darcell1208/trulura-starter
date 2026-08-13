import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme/trulura_theme.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';

import 'package:trulura/features/onboarding/onboarding_scaffold.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  static const _stepTitles = [
    'Basics',
    'Identity',
    'Lifestyle',
    'Expression',
  ];
  static const _interestOptions = [
    'Anime',
    'Travel',
    'Cooking',
    'Gaming',
    'Parenting',
    'Music',
    'Healing',
    'Fitness',
    'Creativity',
    'Emotional Depth',
  ];
  static const _socialPreferences = [
    'Public energy',
    'Balanced energy',
    'Private energy',
  ];

  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _age = TextEditingController();
  final _location = TextEditingController();
  final _pronouns = TextEditingController();
  final _bio = TextEditingController();
  final _photoUrl = TextEditingController();
  final _promptAnswer = TextEditingController();
  final _expressionVibeTag = TextEditingController();
  final _shortPost = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  bool _pickingPhoto = false;
  int _step = 0;
  Uint8List? _pickedPhotoBytes;

  User? _currentUser;
  TruIdentityMode _mode = TruIdentityMode.social;
  TruVibeLabel _vibe = TruVibeLabel.oldSoul;
  String? _intent;
  String? _socialPreference;
  final Set<String> _selectedInterests = <String>{};

  String _resolveReturnTo() {
    final extraReturnTo = TruNavigation.resolveReturnTo(context);
    if (extraReturnTo != null) return extraReturnTo;
    final route = GoRouterState.of(context).uri.queryParameters['returnTo'];
    if (route != null && route.trim().isNotEmpty) return route;
    return AppRoutes.homeTab('aura');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _age.dispose();
    _location.dispose();
    _pronouns.dispose();
    _bio.dispose();
    _photoUrl.dispose();
    _promptAnswer.dispose();
    _expressionVibeTag.dispose();
    _shortPost.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await UserService().getCurrentUser();
      if (!mounted) return;
      _currentUser = user;
      _displayName.text = user == null || user.publicDisplayName == 'New member'
          ? ''
          : user.name;
      _username.text = (user?.username ?? '').toLowerCase();
      _age.text = user == null || user.age <= 0 ? '' : '${user.age}';
      _location.text = user?.location ?? '';
      _pronouns.text = user?.pronouns ?? '';
      _bio.text = user?.bio ?? '';
      _photoUrl.text = user?.profileImage ?? '';
      _promptAnswer.text = user?.expressionPromptAnswer ?? '';
      _expressionVibeTag.text = user?.expressionVibeTag ?? '';
      _shortPost.text = user?.expressionShortPost ?? '';
      _mode = user?.activeIdentityMode ?? TruIdentityMode.social;
      _vibe = user?.vibeLabel ?? TruVibeLabel.oldSoul;
      _intent = user?.intents.firstOrNull;
      _socialPreference = user?.socialPreference;
      _selectedInterests
        ..clear()
        ..addAll(user?.interests ?? const <String>[]);
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('ProfileSetupScreen._load failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  User? _draftUser() {
    final existing = _currentUser;
    if (existing == null) return null;
    return existing.copyWith(
      name: User.publicDisplayNameFrom(
        _displayName.text,
        email: existing.email,
        fallback: 'New member',
      ),
      username: _normalizedUsername(_username.text),
      age: int.tryParse(_age.text.trim()) ?? existing.age,
      location: _nullIfBlank(_location.text),
      pronouns: _nullIfBlank(_pronouns.text),
      bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
      profileImage:
          _photoUrl.text.trim().isEmpty ? null : _photoUrl.text.trim(),
      activeIdentityMode: _mode,
      vibeLabel: _vibe,
      intents: _intent == null ? existing.intents : <String>[_intent!],
      interests: _selectedInterests.toList(growable: false),
      socialPreference: _socialPreference,
      expressionPromptAnswer: _nullIfBlank(_promptAnswer.text),
      expressionVibeTag: _nullIfBlank(_expressionVibeTag.text),
      expressionShortPost: _nullIfBlank(_shortPost.text),
      updatedAt: DateTime.now(),
    );
  }

  String? _nullIfBlank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _normalizedUsername(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('@', '')
        .replaceAll(RegExp(r'\s+'), '');
  }

  Future<void> _pickProfilePhoto() async {
    if (_pickingPhoto) return;
    setState(() => _pickingPhoto = true);
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1600,
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedPhotoBytes = bytes;
        _photoUrl.text = picked.path;
      });
    } catch (e) {
      debugPrint('ProfileSetupScreen._pickProfilePhoto failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not select a photo right now.')),
      );
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  void _clearProfilePhoto() {
    setState(() {
      _pickedPhotoBytes = null;
      _photoUrl.clear();
    });
  }

  double _stepCompletionFor(int step) {
    switch (step) {
      case 0:
        final required = <bool>[
          _displayName.text.trim().isNotEmpty,
          _normalizedUsername(_username.text).isNotEmpty,
          _age.text.trim().isNotEmpty,
          _location.text.trim().isNotEmpty,
          _photoUrl.text.trim().isNotEmpty,
          _bio.text.trim().isNotEmpty,
        ];
        return required.where((done) => done).length / required.length;
      case 1:
        return 1.0;
      case 2:
        final required = <bool>[
          (_intent ?? '').trim().isNotEmpty,
          (_socialPreference ?? '').trim().isNotEmpty,
          _selectedInterests.isNotEmpty,
        ];
        return required.where((done) => done).length / required.length;
      case 3:
        final completed = [
          _promptAnswer.text.trim().isNotEmpty,
          _expressionVibeTag.text.trim().isNotEmpty,
          _shortPost.text.trim().isNotEmpty,
        ].where((done) => done).length;
        return completed / 3;
      default:
        return 0;
    }
  }

  double _onboardingProgressValue() {
    final finishedSteps = _step.clamp(0, _stepTitles.length - 1);
    final progress =
        (finishedSteps + _stepCompletionFor(_step)) / _stepTitles.length;
    return progress.clamp(0.0, 0.95);
  }

  int _onboardingPercent() => (_onboardingProgressValue() * 100).round();

  String _progressMessage() {
    return switch (_step) {
      0 => 'Add the basics people should see first: name, username, age, location, photo, and bio.',
      1 => 'Choose the identity layer that sets your current tone.',
      2 => 'Set intent, social preference, and interests so discovery feels accurate.',
      3 => 'Expression is your finishing layer: prompt, vibe tag, and short post.',
      _ => 'Finish the profile basics you want to share.',
    };
  }

  Future<void> _finish() async {
    if (_saving) return;
    final draft = _draftUser();
    if (draft == null) {
      if (!mounted) return;
      context.go(_resolveReturnTo());
      return;
    }

    setState(() => _saving = true);
    try {
      final app = context.read<AppProvider>();
      await UserService().saveUser(draft);
      await app.refreshCurrentUserFromSupabase();
      if (!mounted) return;
      context.go(_resolveReturnTo());
    } catch (e) {
      debugPrint('ProfileSetupScreen._finish failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save profile. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _canContinue() {
    switch (_step) {
      case 0:
        return _displayName.text.trim().isNotEmpty &&
            _username.text.trim().isNotEmpty;
      case 1:
        return true;
      case 2:
        return _selectedInterests.isNotEmpty;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _continue() {
    if (!_canContinue()) return;
    if (_step == _stepTitles.length - 1) {
      _finish();
      return;
    }
    setState(() => _step += 1);
  }

  @override
  Widget build(BuildContext context) {
    final onboardingPercent = _onboardingPercent();

    return TruLuraOnboardingScaffold(
      title: 'Profile setup',
      subtitle:
          'This walkthrough covers the profile fields collected right now: basics, identity, lifestyle, and expression.',
      child: TruLuraGlassCard(
        child: _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${_step + 1} of ${_stepTitles.length} • ${_stepTitles[_step]}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (_step + 1) / _stepTitles.length,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Text(
                      'Setup progress: $onboardingPercent% • ${_progressMessage()}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int i = 0; i < _stepTitles.length; i++)
                        _ProgressChip(
                          label: _stepTitles[i],
                          complete:
                              i < _step ||
                              (i == _step && _stepCompletionFor(i) >= 1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStep(context),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      if (_step > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => setState(() => _step -= 1),
                            child: const Text('Back'),
                          ),
                        ),
                      if (_step > 0) const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: TruluraTheme.primaryGlow,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed:
                                  _saving || !_canContinue() ? null : _continue,
                              child: _saving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _step == _stepTitles.length - 1
                                          ? 'Save profile'
                                          : 'Continue',
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => context.go(_resolveReturnTo()),
                    child: const Text('Finish later'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 0:
        return _buildBasicsStep();
      case 1:
        return _buildIdentityStep(context);
      case 2:
        return _buildLifestyleStep(context);
      case 3:
      default:
        return _buildExpressionStep();
    }
  }

  Widget _buildBasicsStep() {
    final hasPhoto = _photoUrl.text.trim().isNotEmpty;
    final photo = _photoUrl.text.trim();
    final photoUri = Uri.tryParse(photo);
    final isNetworkPhoto = photoUri != null && photoUri.hasScheme;
    final normalizedUsername = _normalizedUsername(_username.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(
          controller: _displayName,
          label: 'Display name',
          hint: 'What people should see first',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _username,
          label: 'Username',
          hint: 'How people find you',
          onChanged: (value) {
            final normalized = _normalizedUsername(value);
            if (normalized != value) {
              _username.value = TextEditingValue(
                text: normalized,
                selection: TextSelection.collapsed(offset: normalized.length),
              );
            }
            setState(() {});
          },
        ),
        if (normalizedUsername.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '@$normalizedUsername',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
        const SizedBox(height: 12),
        _Field(
          controller: _age,
          label: 'Age',
          hint: 'Your age for now',
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _location,
          label: 'Location',
          hint: 'City or region',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _pronouns,
          label: 'Pronouns (optional)',
          hint: 'she/her, he/him, they/them...',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white12,
            backgroundImage: _pickedPhotoBytes != null
                ? MemoryImage(_pickedPhotoBytes!)
                : hasPhoto
                ? (isNetworkPhoto
                    ? NetworkImage(photo)
                    : AssetImage(photo) as ImageProvider<Object>)
                : null,
            child: hasPhoto
                ? null
                : const Icon(Icons.person, size: 42, color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickingPhoto ? null : _pickProfilePhoto,
                icon: _pickingPhoto
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library_outlined),
                label: Text(hasPhoto ? 'Change photo' : 'Choose photo'),
              ),
            ),
            if (hasPhoto) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: _pickingPhoto ? null : _clearProfilePhoto,
                child: const Text('Remove'),
              ),
            ],
          ],
        ),
        if (hasPhoto) ...[
          const SizedBox(height: 8),
          Text(
            'Photo selected and stored internally for your profile.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
        const SizedBox(height: 12),
        _Field(
          controller: _bio,
          label: 'Short bio',
          maxLines: 4,
          hint: 'One calm, real intro is enough',
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildIdentityStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Persona',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final mode in const [
              TruIdentityMode.social,
              TruIdentityMode.dating,
              TruIdentityMode.creator,
              TruIdentityMode.friendship,
            ])
              _ChoiceChip(
                label: mode.label,
                selected: _mode == mode,
                onTap: () => setState(() => _mode = mode),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Primary vibe',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<TruVibeLabel>(
          initialValue: _vibe,
          items: TruVibeLabel.values
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(v.label),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) setState(() => _vibe = value);
          },
          decoration: const InputDecoration(labelText: 'Choose your vibe'),
        ),
      ],
    );
  }

  Widget _buildLifestyleStep(BuildContext context) {
    const intentOptions = [
      'Social',
      'Dating',
      'Friendship',
      'Creator',
      'Exploring',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _intent,
          items: intentOptions
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(growable: false),
          onChanged: (value) => setState(() => _intent = value),
          decoration: const InputDecoration(
            labelText: 'Intent',
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Social preference',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in _socialPreferences)
              _ChoiceChip(
                label: option,
                selected: _socialPreference == option,
                onTap: () => setState(() => _socialPreference = option),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Interests',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final interest in _interestOptions)
              _ChoiceChip(
                label: interest,
                selected: _selectedInterests.contains(interest),
                onTap: () {
                  setState(() {
                    if (_selectedInterests.contains(interest)) {
                      _selectedInterests.remove(interest);
                    } else {
                      _selectedInterests.add(interest);
                    }
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpressionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add at least one expression layer if you want your profile to feel more alive.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _promptAnswer,
          label: 'Prompt answer',
          maxLines: 3,
          hint: 'What kind of energy do you bring into a room?',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _expressionVibeTag,
          label: 'Vibe tag',
          hint: 'Calm depth, playful honesty, gentle chaos...',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _shortPost,
          label: 'Short post',
          maxLines: 3,
          hint: 'A short thought people can feel immediately',
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final String label;
  final bool complete;

  const _ProgressChip({required this.label, required this.complete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: complete ? 0.12 : 0.06),
        border: Border.all(
          color: Colors.white.withValues(alpha: complete ? 0.20 : 0.10),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: TruluraTheme.cyan),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TruLuraGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? TruluraTheme.cyan : Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
