import 'package:trulura/widgets/trulura_glass_card.dart';

/// Trulura public component library.
///
/// Provides stable, spec-aligned names (`Trulura*`) while keeping existing
/// implementations intact.

import 'package:trulura/widgets/feed_card.dart' show FeedCard;
import 'package:trulura/widgets/sync_hero_card.dart' show SyncHeroCard;
import 'package:trulura/widgets/trulura_bottom_nav.dart' show TruLuraBottomNav;
import 'package:trulura/widgets/trulura_glass_app_bar.dart'
    show TruLuraGlassAppBar;
import 'package:trulura/widgets/trulura_glass_card.dart' show TruLuraGlassCard;
import 'package:trulura/widgets/trulura_halo_avatar.dart'
    show TruLuraHaloAvatar;
import 'package:trulura/widgets/trulura_primary_button.dart'
    show TruLuraPrimaryButton;
import 'package:trulura/widgets/trulura_secondary_buttons.dart'
    show SecondaryGlassButton, TruluraActionButton;
import 'package:trulura/widgets/trulura_side_drawer.dart'
    show TruLuraSideDrawer;

// Core primitives
export 'package:trulura/widgets/trulura_glass_card.dart';
export 'package:trulura/widgets/trulura_halo_avatar.dart';
export 'package:trulura/widgets/trulura_glass_app_bar.dart';
export 'package:trulura/widgets/trulura_bottom_nav.dart';
export 'package:trulura/widgets/trulura_side_drawer.dart';
export 'package:trulura/widgets/trulura_layered_background.dart';
export 'package:trulura/widgets/trulura_primary_button.dart';
export 'package:trulura/widgets/trulura_secondary_buttons.dart';
export 'package:trulura/widgets/trulura_screen_state.dart';
export 'package:trulura/widgets/trulura_screen_shell.dart';

// Spec components (implemented)
export 'package:trulura/widgets/trulura_compatibility_badge.dart';
export 'package:trulura/widgets/trulura_status_badge.dart';
export 'package:trulura/widgets/trulura_search_field.dart';
export 'package:trulura/widgets/trulura_segmented_pill.dart';
export 'package:trulura/widgets/trulura_pill_chip.dart';
export 'package:trulura/widgets/trulura_reaction_button.dart';
export 'package:trulura/widgets/trulura_conversation_tile.dart';
export 'package:trulura/widgets/trulura_message_bubble.dart';
export 'package:trulura/widgets/trulura_profile_hero_card.dart';
export 'package:trulura/widgets/trulura_profile_tab_bar.dart';
export 'package:trulura/widgets/trulura_explore_profile_card.dart';
export 'package:trulura/widgets/trulura_vent_card.dart';
export 'package:trulura/widgets/trulura_companion_mode_card.dart';
export 'package:trulura/widgets/trulura_empty_state_card.dart';
export 'package:trulura/widgets/trulura_skeleton_card.dart';
export 'package:trulura/widgets/trulura_feed_components.dart';
export 'package:trulura/widgets/trulura_feed_item_renderer.dart';
export 'package:trulura/widgets/trulura_post_composer.dart';
export 'package:trulura/models/feed_item.dart';

// Existing higher-level components
export 'package:trulura/widgets/feed_card.dart';
export 'package:trulura/widgets/sync_hero_card.dart';
export 'package:trulura/widgets/sync_preview_panel.dart';

// Spec-aligned aliases for existing components.
typedef TruluraGlassCard = TruLuraGlassCard;
typedef TruluraHaloAvatar = TruLuraHaloAvatar;
typedef TruluraTopBar = TruLuraGlassAppBar;
typedef TruluraBottomNav = TruLuraBottomNav;
typedef TruluraSideDrawer = TruLuraSideDrawer;
typedef TruluraPrimaryButton = TruLuraPrimaryButton;
typedef TruluraSecondaryButton = SecondaryGlassButton;
typedef TruluraIconButton = TruluraActionButton;
typedef TruluraFeedPostCard = FeedCard;
typedef TruluraSyncHeroCard = SyncHeroCard;
