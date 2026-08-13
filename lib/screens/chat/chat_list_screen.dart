import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/models/chat.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/services/chat_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_halo_avatar.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_screen_state.dart';
import 'package:trulura/widgets/trulura_conversation_tile.dart';
import 'package:trulura/widgets/trulura_feed_components.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _search = TextEditingController();
  List<Chat> _chats = [];
  bool _isLoading = true;
  bool _hasError = false;

  final Set<String> _pinned = <String>{};
  final Set<String> _archived = <String>{};

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    try {
      final user = await UserService().getCurrentUser();
      if (user != null) {
        final chats = await _chatService.getAllChats(user.id);
        setState(() {
          _chats = chats;
          _hasError = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      truLogStateError('ChatList._loadChats', e);
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui =
        truParseUiState(GoRouterState.of(context).uri.queryParameters['ui']);
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;

    final q = _search.text.trim().toLowerCase();
    final visibleChats =
        _chats.where((c) => !_archived.contains(c.id)).toList();
    final filtered = q.isEmpty
        ? visibleChats
        : visibleChats.where((c) {
            final other =
                c.participants.isNotEmpty ? c.participants.first : null;
            final name = other?.name.toLowerCase() ?? '';
            final handle = other?.username.toLowerCase() ?? '';
            return name.contains(q) ||
                handle.contains(q) ||
                (c.lastMessage ?? '').toLowerCase().contains(q);
          }).toList();

    filtered.sort((a, b) {
      final ap = _pinned.contains(a.id) ? 0 : 1;
      final bp = _pinned.contains(b.id) ? 0 : 1;
      if (ap != bp) return ap.compareTo(bp);
      return (b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(
              a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0));
    });

    return Column(
      children: [
        TruluraContentLane(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: soft
                    ? TruLuraSurfaces.glassBlurSoft
                    : TruLuraSurfaces.glassBlurStrong,
                sigmaY: soft
                    ? TruLuraSurfaces.glassBlurSoft
                    : TruLuraSurfaces.glassBlurStrong,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.surface.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? TruLuraSurfaces.glassDarkA
                              : TruLuraSurfaces.glassLightA),
                      cs.surfaceContainerHighest.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? TruLuraSurfaces.glassDarkB
                              : TruLuraSurfaces.glassLightB),
                    ],
                  ),
                  border: Border.all(
                      color:
                          Colors.white.withValues(alpha: soft ? 0.10 : 0.085),
                      width: TruLuraSurfaces.hairline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search TruMessages…',
                          prefixIcon: const Padding(
                              padding: EdgeInsets.all(12),
                              child: TruLuraIcon(
                                  glyph: TruLuraGlyph.search, size: 20)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest
                              .withValues(alpha: 0.62),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Consumer<AppProvider>(
                      builder: (context, provider, _) => IconButton(
                        icon: TruLuraIcon(
                          glyph: provider.lowSocialBattery
                              ? TruLuraGlyph.batteryCharging
                              : TruLuraGlyph.battery,
                          size: 22,
                          active: provider.lowSocialBattery,
                          color: provider.lowSocialBattery
                              ? cs.secondary
                              : cs.onSurfaceVariant,
                        ),
                        onPressed: provider.toggleLowSocialBattery,
                        tooltip: 'Low Aura Battery',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: ui == TruUiState.loading
                    ? const _ChatListSkeleton()
                    : ui == TruUiState.empty
                        ? TruStatePanel(
                            glyph: TruLuraGlyph.messages,
                            title: 'Your conversations will appear here',
                            message:
                                'Start a connection in Sync or Explore — then TruMessages lights up instantly.',
                            actions: [
                              TruStateAction(
                                  label: 'Visit Sync',
                                  glyph: TruLuraGlyph.sync,
                                  onTap: () =>
                                      context.go(AppRoutes.homeTab('sync')),
                                  primary: true),
                              TruStateAction(
                                  label: 'Explore people',
                                  glyph: TruLuraGlyph.explore,
                                  onTap: () =>
                                      context.go(AppRoutes.homeTab('explore'))),
                            ],
                          )
                        : ui == TruUiState.action
                            ? const Center(
                                child: TruInlineBanner(
                                    glyph: TruLuraGlyph.info,
                                    text:
                                        'A conversation is paused • Messaging unlocks when connection is approved.'))
                            : _isLoading
                                ? const _ChatListSkeleton()
                                : _hasError
                                    ? TruStatePanel(
                                        glyph: TruLuraGlyph.info,
                                        title: 'We couldn’t load your messages',
                                        message: 'Try again in a moment.',
                                        actions: [
                                          TruStateAction(
                                              label: 'Retry',
                                              glyph: TruLuraGlyph.spark,
                                              onTap: _loadChats,
                                              primary: true)
                                        ],
                                      )
                                    : _chats.isEmpty
                                        ? TruStatePanel(
                                            glyph: TruLuraGlyph.messages,
                                            title: 'No conversations yet',
                                            message:
                                                'Start by connecting through Aura, Explore, or Sync — then your inbox will appear here.',
                                            actions: [
                                              TruStateAction(
                                                  label: 'Go to Aura',
                                                  glyph: TruLuraGlyph.aura,
                                                  onTap: () => context.go(
                                                      AppRoutes.homeTab(
                                                          'aura')),
                                                  primary: true),
                                              TruStateAction(
                                                  label: 'Explore',
                                                  glyph: TruLuraGlyph.explore,
                                                  onTap: () => context.go(
                                                      AppRoutes.homeTab(
                                                          'explore'))),
                                            ],
                                          )
                                        : filtered.isEmpty
                                            ? TruStatePanel(
                                                glyph: TruLuraGlyph.search,
                                                title:
                                                    'No conversations matched that search',
                                                message:
                                                    'Try a different name or handle.',
                                                actions: [
                                                  TruStateAction(
                                                    label: 'Clear search',
                                                    glyph: TruLuraGlyph.close,
                                                    onTap: () {
                                                      _search.clear();
                                                      setState(() {});
                                                    },
                                                    primary: true,
                                                  ),
                                                ],
                                              )
                                            : TruluraContentLane(
                                                padding: EdgeInsets.zero,
                                                child: ListView(
                                                  padding: const EdgeInsets
                                                      .fromLTRB(16, 6, 16,
                                                      kTruluraBottomNavClearance),
                                                  children: [
                                                    if (app
                                                        .lowSocialBattery) ...[
                                                      const TruInlineBanner(
                                                        glyph: TruLuraGlyph
                                                            .batteryCharging,
                                                        text:
                                                            'Low Social Battery enabled • Responses may be slower, no pressure.',
                                                      ),
                                                      const SizedBox(
                                                          height: 12),
                                                    ],
                                                    ...List.generate(
                                                        filtered.length,
                                                        (index) {
                                                      final chat =
                                                          filtered[index];
                                                      final otherUser = chat
                                                              .participants
                                                              .isNotEmpty
                                                          ? chat.participants
                                                              .first
                                                          : null;
                                                      final name = otherUser
                                                              ?.publicDisplayName ??
                                                          'New member';
                                                      final subtitle = (chat
                                                                  .lastMessage
                                                                  ?.trim()
                                                                  .isNotEmpty ??
                                                              false)
                                                          ? chat.lastMessage!
                                                              .trim()
                                                          : 'No messages';
                                                      final isPinned = _pinned
                                                          .contains(chat.id);
                                                      return Padding(
                                                        padding: EdgeInsets.only(
                                                            bottom: index ==
                                                                    filtered.length -
                                                                        1
                                                                ? 0
                                                                : 12),
                                                        child: Dismissible(
                                                          key: ValueKey(
                                                              'chat_${chat.id}'),
                                                          background: _SwipeBg(
                                                              icon: Icons
                                                                  .push_pin_rounded,
                                                              label: isPinned
                                                                  ? 'Unpin'
                                                                  : 'Pin',
                                                              alignment: Alignment
                                                                  .centerLeft),
                                                          secondaryBackground:
                                                              const _SwipeBg(
                                                                  icon: Icons
                                                                      .archive_rounded,
                                                                  label:
                                                                      'Archive',
                                                                  alignment:
                                                                      Alignment
                                                                          .centerRight),
                                                          confirmDismiss:
                                                              (direction) async {
                                                            if (direction ==
                                                                DismissDirection
                                                                    .startToEnd) {
                                                              setState(() {
                                                                if (isPinned) {
                                                                  _pinned.remove(
                                                                      chat.id);
                                                                } else {
                                                                  _pinned.add(
                                                                      chat.id);
                                                                }
                                                              });
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(SnackBar(
                                                                      content: Text(isPinned
                                                                          ? 'Unpinned'
                                                                          : 'Pinned')));
                                                              return false;
                                                            }
                                                            if (direction ==
                                                                DismissDirection
                                                                    .endToStart) {
                                                              setState(() =>
                                                                  _archived.add(
                                                                      chat.id));
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      const SnackBar(
                                                                          content:
                                                                              Text('Archived')));
                                                              return false;
                                                            }
                                                            return false;
                                                          },
                                                          child:
                                                              TruluraConversationTile(
                                                            name: name,
                                                            subtitle: subtitle,
                                                            status: chat.status,
                                                            avatar: otherUser
                                                                        ?.profileImage !=
                                                                    null
                                                                ? AssetImage(
                                                                    otherUser!
                                                                        .profileImage!)
                                                                : null,
                                                            pinned: isPinned,
                                                            onTap: () =>
                                                                context.push(
                                                                    '/chat/${chat.id}'),
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                  ],
                                                ),
                                              ),
              ),
              Positioned(
                right: 18,
                bottom: kTruluraBottomNavClearance - 24,
                child: FloatingActionButton.extended(
                  onPressed: () => context.push(
                      '/p?title=${Uri.encodeComponent('New Message')}&subtitle=${Uri.encodeComponent('Start conversation (stub)')}'),
                  elevation: 0,
                  backgroundColor: cs.primary,
                  icon: Icon(Icons.edit_rounded, color: cs.onPrimary),
                  label: Text('New',
                      style: TextStyle(
                          color: cs.onPrimary, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatListSkeleton extends StatelessWidget {
  const _ChatListSkeleton();

  @override
  Widget build(BuildContext context) {
    return TruShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return TruLuraGlassCard(
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: const [
                TruSkeletonCircle(size: 52),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TruSkeletonBox(width: 160, height: 14, radius: 10),
                      SizedBox(height: 10),
                      TruSkeletonBox(width: 220, height: 12, radius: 10),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                TruSkeletonBox(width: 72, height: 26, radius: 999),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChatRow extends StatefulWidget {
  final String name;
  final String subtitle;
  final String status;
  final ImageProvider? avatar;
  final VoidCallback onTap;
  final bool pinned;

  const _ChatRow(
      {required this.name,
      required this.subtitle,
      required this.status,
      required this.avatar,
      required this.onTap,
      required this.pinned});

  @override
  State<_ChatRow> createState() => _ChatRowState();
}

class _ChatRowState extends State<_ChatRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    final isActive = widget.status.toLowerCase() == 'active';

    final Color pillBg =
        isActive ? cs.tertiaryContainer : cs.surfaceContainerHighest;
    final Color pillFg = isActive
        ? cs.onTertiaryContainer
        : cs.onSurface.withValues(alpha: 0.72);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.985 : 1,
        child: TruLuraGlassCard(
          radius: 22,
          tone: TruLuraModeTone.aura,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          gradientStroke: !soft,
          child: Row(
            children: [
              TruLuraHaloAvatar(
                radius: 26,
                image: widget.avatar,
                fallback:
                    const TruLuraIcon(glyph: TruLuraGlyph.person, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.70),
                            height: 1.25)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (widget.pinned) ...[
                Icon(Icons.push_pin_rounded,
                    size: 18, color: cs.secondary.withValues(alpha: 0.92)),
                const SizedBox(width: 8),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: soft ? 0.10 : 0.12),
                      width: TruLuraSurfaces.hairline),
                ),
                child: Text(widget.status,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: pillFg,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  final IconData icon;
  final String label;
  final Alignment alignment;

  const _SwipeBg(
      {required this.icon, required this.label, required this.alignment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cs.onSurface.withValues(alpha: 0.86)),
          const SizedBox(width: 10),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
