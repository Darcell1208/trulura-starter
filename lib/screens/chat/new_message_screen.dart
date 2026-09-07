import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/chat_service.dart';
import 'package:trulura/widgets/trulura_glass_app_bar.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_halo_avatar.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/trulura_screen_state.dart';

/// Picks somebody to message and opens the thread with them.
///
/// Replaces the placeholder `/p?title=New%20Message` route the messages FAB
/// used to push, which rendered a generic "stub" panel and could not create
/// anything.
///
/// Selection goes through `start_direct_conversation`, which is idempotent, so
/// choosing somebody you already have a thread with lands in that thread
/// instead of creating a duplicate.
class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _search = TextEditingController();

  List<User> _people = const <User>[];
  bool _isLoading = true;

  /// The user-facing reason loading failed, or null when it succeeded. Held as
  /// a message rather than a bool so the screen can name the actual cause --
  /// signed out, offline, or a database error -- instead of showing one
  /// catch-all panel.
  String? _loadError;

  /// Id of the person whose conversation is currently being created, so only
  /// that row shows a spinner and repeat taps are ignored while it is in
  /// flight. A second tap would be harmless -- the RPC is idempotent -- but it
  /// would race two navigations.
  String? _startingFor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final people = await _chatService.getConnectableProfiles();
      if (!mounted) return;
      setState(() {
        _people = people;
        _isLoading = false;
      });
    } on StartConversationException catch (e) {
      truLogStateError('NewMessage._load', e);
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _isLoading = false;
      });
    } catch (e) {
      truLogStateError('NewMessage._load', e);
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load people to message. Try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _start(User person) async {
    if (_startingFor != null) return;
    setState(() => _startingFor = person.id);
    try {
      final conversationId =
          await _chatService.startDirectConversation(person.id);
      if (!mounted) return;
      // pushReplacement, not push: the picker has done its job, and Back from
      // the thread should return to the inbox rather than back to the list of
      // people with the thread already open behind it.
      context.pushReplacement('/messages/thread/$conversationId');
    } on StartConversationException catch (e) {
      truLogStateError('NewMessage._start', e);
      if (!mounted) return;
      setState(() => _startingFor = null);
      _showError(e.message);
    } catch (e) {
      truLogStateError('NewMessage._start', e);
      if (!mounted) return;
      setState(() => _startingFor = null);
      _showError('Could not start the conversation. Try again.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ));
  }

  String _displayName(User person) {
    if (person.name.trim().isNotEmpty) return person.name.trim();
    if (person.username.trim().isNotEmpty) return '@${person.username.trim()}';
    return 'Someone on Trulura';
  }

  String _subtitle(User person) {
    if (person.username.trim().isNotEmpty) return '@${person.username.trim()}';
    final bio = (person.bio ?? '').trim();
    return bio.isEmpty ? 'Tap to start a conversation' : bio;
  }

  List<User> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _people;
    return _people.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.username.toLowerCase().contains(q) ||
          (p.bio ?? '').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const TruLuraGlassAppBar(title: 'New Message'),
      body: TruLuraLayeredBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TruLuraGlassCard(
                  radius: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search people',
                      icon: Icon(Icons.search_rounded,
                          color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const _PeopleSkeleton();

    if (_loadError != null) {
      return TruStatePanel(
        glyph: TruLuraGlyph.info,
        title: 'We couldn’t load people to message',
        message: _loadError!,
        actions: [
          TruStateAction(
              label: 'Retry',
              glyph: TruLuraGlyph.spark,
              onTap: _load,
              primary: true),
        ],
      );
    }

    if (_people.isEmpty) {
      return TruStatePanel(
        glyph: TruLuraGlyph.messages,
        title: 'Nobody to message yet',
        message:
            'When you connect with people through Aura, Explore, or Sync, they’ll show up here.',
        actions: [
          TruStateAction(
              label: 'Explore people',
              glyph: TruLuraGlyph.explore,
              onTap: () => context.go('/home/explore'),
              primary: true),
        ],
      );
    }

    final people = _filtered;
    if (people.isEmpty) {
      return TruStatePanel(
        glyph: TruLuraGlyph.info,
        title: 'No matches',
        message: 'Nobody matches “${_search.text.trim()}”.',
        actions: [
          TruStateAction(
            label: 'Clear search',
            glyph: TruLuraGlyph.spark,
            onTap: () {
              _search.clear();
              setState(() {});
            },
            primary: true,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: people.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final person = people[index];
        final busy = _startingFor == person.id;
        return _PersonRow(
          name: _displayName(person),
          subtitle: _subtitle(person),
          photoUrl: person.profileImage,
          busy: busy,
          // Any row is inert while another is starting, so a stray tap cannot
          // race a second navigation.
          onTap: _startingFor == null ? () => _start(person) : null,
        );
      },
    );
  }
}

class _PersonRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? photoUrl;
  final bool busy;
  final VoidCallback? onTap;

  const _PersonRow({
    required this.name,
    required this.subtitle,
    required this.photoUrl,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = (photoUrl ?? '').trim();

    return Opacity(
      opacity: onTap == null && !busy ? 0.5 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: TruLuraGlassCard(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              TruLuraHaloAvatar(
                radius: 24,
                image: url.isEmpty ? null : NetworkImage(url),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeopleSkeleton extends StatelessWidget {
  const _PeopleSkeleton();

  @override
  Widget build(BuildContext context) {
    return TruShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => TruLuraGlassCard(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: const [
              TruSkeletonCircle(size: 48),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TruSkeletonBox(width: 150, height: 14, radius: 10),
                    SizedBox(height: 8),
                    TruSkeletonBox(width: 200, height: 12, radius: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
