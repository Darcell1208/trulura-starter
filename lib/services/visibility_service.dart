import 'package:flutter/foundation.dart';
import 'package:trulura/models/experience/experience_mode.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/models/user.dart';

/// Mode + privacy + trust visibility engine.
///
/// This is designed to keep the *policy* centralized so feeds, explore, and
/// interactions can all enforce the same segmentation rules.
class VisibilityService {
  const VisibilityService();

  List<Post> filterPosts({required List<Post> posts, required TruParticipationContext ctx, required User? viewer}) {
    return posts.where((p) => canViewPost(post: p, ctx: ctx, viewer: viewer).allowed).toList(growable: false);
  }

  TruVisibilityDecision canViewPost({required Post post, required TruParticipationContext ctx, required User? viewer}) {
    // Author can always view their own content.
    if (viewer != null && post.userId == viewer.id) return const TruVisibilityDecision.allowed();

    final inferred = post.inferredExperienceMode();
    final priv = post.privacy.trim().toLowerCase();

    // 1) Mode-based segmentation (core rule).
    if (!_isPostInModeWorld(post: post, ctx: ctx)) {
      return const TruVisibilityDecision.denied('Cross-mode content is suppressed.');
    }

    // 2) Youth separation (hard boundary).
    if (ctx.isYouthContext) {
      if (post.isAnonymous) return const TruVisibilityDecision.denied('Youth mode hides anonymous posts.');
      if (priv != 'public') return const TruVisibilityDecision.denied('Youth mode only shows public posts.');
      if (inferred.isAdultIntent) return const TruVisibilityDecision.denied('Adult-intent posts are hidden in Youth.');
    }

    // 3) Protected emotional spaces (no bleed).
    if (ctx.isProtectedEmotionalSpace && inferred != TruExperienceMode.vent) {
      return const TruVisibilityDecision.denied('Vent space is isolated by intent.');
    }

    // 4) Post-level privacy.
    if (priv == 'private') return const TruVisibilityDecision.denied('Private post.');
    if (priv == 'friends') {
      // Friends graph not implemented yet, so treat as not visible by default.
      return const TruVisibilityDecision.denied('Friends-only post (not available yet).');
    }

    // 5) Trust/identity tier access (viewer-based).
    // If the viewer cannot enter a mode due to verification, they also shouldn't
    // be surfaced that mode's content in other contexts.
    if (viewer != null && inferred.isAdultIntent) {
      if (viewer.age < 18) return const TruVisibilityDecision.denied('Adult-intent content requires 18+.');
      if (inferred == TruExperienceMode.dating && viewer.verificationLevel == TruVerificationLevel.level0) {
        return const TruVisibilityDecision.denied('Dating content requires basic verification.');
      }
      if (inferred == TruExperienceMode.luxe && viewer.verificationLevel.index < TruVerificationLevel.level2.index) {
        return const TruVisibilityDecision.denied('Luxe content requires verified identity.');
      }
      if (inferred == TruExperienceMode.altIntimate && viewer.verificationLevel.index < TruVerificationLevel.level3.index) {
        return const TruVisibilityDecision.denied('This content requires trusted verification.');
      }
    }

    // 6) Monetized visibility protection (placeholder policy).
    // Until monetization is implemented, we keep a policy hook here so “boosting”
    // can never override protected contexts.
    if (ctx.effectivePermissions.suppressVirality && inferred.isProtectedSpace) {
      // Always allowed; but this is where you would explicitly block any paid
      // placement / ranking overrides.
    }

    return const TruVisibilityDecision.allowed();
  }

  bool _isPostInModeWorld({required Post post, required TruParticipationContext ctx}) {
    // Mirrors the previous HomeFeedScreen logic, but centralized.
    final inferred = post.inferredExperienceMode();

    if (ctx.isYouthContext) return true;
    if (ctx.isProtectedEmotionalSpace) return inferred == TruExperienceMode.vent;

    switch (ctx.activeMode) {
      case TruExperienceMode.social:
        if (inferred == TruExperienceMode.social) return true;
        if (ctx.passiveModes.contains(TruExperienceMode.friendship) && inferred == TruExperienceMode.friendship) return true;
        if (ctx.passiveModes.contains(TruExperienceMode.creator) && inferred == TruExperienceMode.creator) return true;
        return false;
      case TruExperienceMode.friendship:
        return inferred == TruExperienceMode.friendship || inferred == TruExperienceMode.social;
      case TruExperienceMode.creator:
        return inferred == TruExperienceMode.creator || inferred == TruExperienceMode.social;
      case TruExperienceMode.dating:
        return inferred == TruExperienceMode.dating || inferred == TruExperienceMode.social;
      case TruExperienceMode.luxe:
        return inferred == TruExperienceMode.luxe || inferred == TruExperienceMode.dating;
      case TruExperienceMode.altIntimate:
        return inferred == TruExperienceMode.altIntimate;
      case TruExperienceMode.youth:
        return true;
      case TruExperienceMode.vent:
        return true;
    }
  }
}

@immutable
class TruVisibilityDecision {
  final bool allowed;
  final String? reason;

  const TruVisibilityDecision._({required this.allowed, this.reason});
  const TruVisibilityDecision.allowed() : this._(allowed: true);
  const TruVisibilityDecision.denied(String reason) : this._(allowed: false, reason: reason);
}
