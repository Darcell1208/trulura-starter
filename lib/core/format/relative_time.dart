/// Human-readable elapsed time for content timestamps.
library;

/// Renders how long ago [at] was, e.g. `2h ago`.
///
/// Coarse on purpose. A Vent card shows this above an anonymous post, so the
/// value has to say roughly when without narrowing who: "3h ago" tells a reader
/// the vent is recent, while a precise clock time would let anyone correlating
/// two surfaces line it up against someone's activity. Buckets widen as the
/// post ages, which is also how people actually read recency.
///
/// [now] is injectable so this can be tested without depending on the clock.
///
/// A negative difference — a post timestamped slightly in the future, which
/// happens when the device clock trails the server's — renders as `just now`
/// rather than something absurd. `createdAt` arrives UTC-flagged from Postgres
/// and `DateTime.difference` compares absolute instants regardless of flag, so
/// no timezone conversion is needed or wanted here.
String relativeTimeAgo(DateTime at, {DateTime? now}) {
  final elapsed = (now ?? DateTime.now()).difference(at);

  if (elapsed.isNegative || elapsed.inSeconds < 45) return 'just now';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
  if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
  if (elapsed.inDays < 7) return '${elapsed.inDays}d ago';
  if (elapsed.inDays < 365) return '${elapsed.inDays ~/ 7}w ago';
  return '${elapsed.inDays ~/ 365}y ago';
}
