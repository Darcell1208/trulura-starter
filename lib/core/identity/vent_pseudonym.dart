/// Display names for anonymous posts.
///
/// Every anonymous post used to render as "Anonymous", which meant five vents
/// from five people were indistinguishable from five vents by one person. A
/// reply thread under one of them was unreadable for the same reason.
///
/// ## The rule this file exists to enforce: derive from the POST, not the user
///
/// [ventPseudonymFor] takes a **post id**. It must never be given a user id.
///
/// That is the whole design, not an implementation detail. A name derived from
/// the author is the same name every time that person vents — a persistent
/// handle that people recognise, form impressions of, and can harass as. That
/// is a second account in everything but storage, and the Blueprint forecloses
/// it: §1.1 says identity layers are "contextual expressions of the same
/// identity system… **not separate accounts**". Per-user pseudonyms were
/// explicitly considered and ruled out on those grounds — see
/// `docs/TruLura_PO_Decision_Vent_Identity_And_Blocking.md`, decision 2.
///
/// Deriving from the post gives the opposite property: the same author posting
/// twice gets two unrelated names, and nothing links them.
///
/// ## Why not redactedId
///
/// `redactedId` in `lib/core/diagnostics/log_redaction.dart` is a similar hash
/// and it is the obvious thing to reach for. Do not. Three reasons:
///
/// 1. It takes a **user id**. Wiring it up here produces per-user pseudonyms by
///    accident — precisely the outcome the decision record rules out.
/// 2. It renders `id#3f2a91c4`. That is a debugging token, not a name; it reads
///    as a hash to a person in a vulnerable moment, and it is not readable in a
///    thread, which is the entire reason names exist here.
/// 3. Its own documentation scopes it to correlating console lines and warns
///    against carrying it into other contexts.
///
/// ## STOP — do not use this for comments
///
/// If you are building comments or replies, [ventPseudonymFor] as written is
/// the wrong function and it will look like the right one, because it is
/// already here and it already takes an id.
///
/// A comment is a separate row with its own id. Passing the comment's id gives
/// one commenter **a different name on every reply**, so a three-reply exchange
/// reads as three strangers — the exact unreadability per-post names were added
/// to fix. Passing the *post's* id gives every participant in the thread the
/// same name, which is worse.
///
/// The rule for comments is to derive from the **post id and the commenter's
/// user id together**, so that one person keeps one name for the length of a
/// thread and gets an unrelated one on a different vent. Nothing links across
/// posts, and the conversation reads. The vent's author is named the same way,
/// from their own user id and their own post id. See decision 2a in
/// `docs/TruLura_PO_Decision_Vent_Identity_And_Blocking.md`.
///
/// That function does not exist yet, deliberately: comments are a stub
/// (`Comment sent (stub)` in feed_card.dart writes nothing). Write it when you
/// write comments; do not bend this one.
///
/// And read decision 2b first. The `comments` table exists with
/// `select USING (true)` for authenticated, so every comment's `user_id` is
/// readable by any signed-in client. Until that is fixed with a nulling view,
/// no naming scheme here means anything — a reader can query the real author,
/// and an author commenting on their own vent deanonymises it.
///
/// ## What this is not
///
/// It is not a security boundary and it is not the anonymity mechanism. The
/// anonymity is enforced upstream: `vent_feed` nulls `user_id` for anonymous
/// rows, so the client never receives the author. This only decides what to
/// print. Blocking likewise never operates on this name — it resolves on
/// `posts.user_id`, which the row still carries (decision 3).
///
/// Collisions are expected and harmless. Two posts can share a name; since
/// names are not meant to link anything, a collision discloses nothing, and
/// arguably reinforces that the name is not an identity.
library;

/// A calm, readable stand-in name derived from [postId].
///
/// Returns something like `Quiet Harbor`. Stable for a given post — the same
/// post always renders the same name, within and across sessions and devices,
/// because it is a pure function of the id. Pass the post's own id and nothing
/// else.
///
/// **Posts only.** Not for comments or replies — that needs post id + commenter
/// user id, and this function will silently give a plausible wrong answer. See
/// "STOP — do not use this for comments" in the library doc above.
///
/// Falls back to `Anonymous` for an empty id, which happens for a post being
/// composed but not yet saved, before the database has assigned one.
String ventPseudonymFor(String? postId) {
  final id = (postId ?? '').trim();
  if (id.isEmpty) return 'Anonymous';

  // FNV-1a, 32-bit. A hash rather than anything reversible because there is no
  // reason for this to be reversible; it is a deterministic pick from two
  // lists, nothing more.
  const int offset = 0x811c9dc5;
  const int prime = 0x01000193;
  const int mask = 0xffffffff;

  var hash = offset;
  for (final unit in id.codeUnits) {
    hash = (hash ^ unit) & mask;
    hash = (hash * prime) & mask;
  }

  // Two independent draws from one hash: the low end picks the adjective, the
  // quotient picks the noun, so the two are not correlated the way adjacent
  // bit-slices of a weak hash can be.
  final adjective = _adjectives[hash % _adjectives.length];
  final noun = _nouns[(hash ~/ _adjectives.length) % _nouns.length];
  return '$adjective $noun';
}

/// Deliberately plain, calm words. Nothing evaluative, nothing that could read
/// as a judgement of the person or of what they wrote — this name sits above
/// someone's account of a bad night.
const List<String> _adjectives = <String>[
  'Quiet', 'Gentle', 'Steady', 'Distant', 'Patient', 'Soft',
  'Still', 'Calm', 'Kind', 'Open', 'Warm', 'Honest',
  'Clear', 'Deep', 'Even', 'Mild', 'Plain', 'Slow',
  'True', 'Wide', 'Bright', 'Amber', 'Autumn', 'Winter',
  'Summer', 'Spring', 'Morning', 'Evening', 'Northern', 'Southern',
  'Eastern', 'Western', 'Hidden', 'Silent', 'Tender', 'Humble',
  'Golden', 'Silver', 'Rising', 'Drifting', 'Wandering', 'Resting',
  'Waiting', 'Simple', 'Level', 'Fair', 'Near', 'Far',
];

const List<String> _nouns = <String>[
  'Harbor', 'Meadow', 'River', 'Lantern', 'Garden', 'Anchor',
  'Horizon', 'Compass', 'Shelter', 'Beacon', 'Willow', 'Cedar',
  'Hollow', 'Summit', 'Current', 'Thicket', 'Orchard', 'Marsh',
  'Ridge', 'Cove', 'Field', 'Grove', 'Shore', 'Tide',
  'Stone', 'Bridge', 'Valley', 'Island', 'Lake', 'Creek',
  'Trail', 'Cabin', 'Hearth', 'Window', 'Doorway', 'Path',
  'Clearing', 'Fountain', 'Terrace', 'Courtyard', 'Pier', 'Bay',
  'Dune', 'Prairie', 'Canyon', 'Basin', 'Wellspring', 'Lighthouse',
];
