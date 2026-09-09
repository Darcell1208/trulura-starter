/// What is safe to put in a log line, in one place.
///
/// The privacy model in this app is enforced in the database and it is sound.
/// Every leak found so far has been downstream of it: a view defined without
/// `security_invoker`, a diagnostic printing id/username/bio, a service
/// printing a whole insert row. Policies get reviewed; log lines do not, and
/// the console is the one surface a screen recording or a pasted bug report
/// copies verbatim.
///
/// So: log named fields, never whole rows or model objects, and route
/// identifiers and errors through here.
library;

import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

/// A short, stable, non-reversible stand-in for an identifier.
///
/// Returns something like `id#3f2a91c4`. The same input always produces the
/// same output within and across runs, which is the property that actually
/// matters when reading a console: you can tell that two failures concern the
/// same target, and correlate a failed block with the retry that follows it.
///
/// Deliberately NOT a truncated UUID. Last-four reads nicely and is a genuine
/// partial identifier -- against a small user base, four hex characters plus
/// the surrounding context is often enough to name the person, and the whole
/// point of redacting a block target is that who you tried to block is private.
/// A hash keeps every debugging property and discloses nothing.
///
/// FNV-1a rather than a crypto hash: this is a log-correlation aid, not a
/// security boundary, and it avoids pulling in a dependency for it. It is not
/// reversible, but it is not salted either, so do not treat it as anonymising
/// a small known set -- it is here to keep raw ids out of logs, nothing more.
String redactedId(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return 'id#none';

  const int offset = 0x811c9dc5;
  const int prime = 0x01000193;
  const int mask = 0xffffffff;

  var hash = offset;
  for (final unit in value.codeUnits) {
    hash = (hash ^ unit) & mask;
    hash = (hash * prime) & mask;
  }
  return 'id#${hash.toRadixString(16).padLeft(8, '0')}';
}

/// A rendering of [error] that is safe to log.
///
/// The case that matters is [PostgrestException]: its `details` and `hint`
/// fields are where Postgres quotes the offending values back at you. A unique
/// violation will happily print the conflicting row, so a constraint failure on
/// a private post can put that post's content in the console without anyone
/// having written a logging line for it. `message` and `code` carry the
/// diagnosis; `details` and `hint` carry the data, and are dropped here.
///
/// [AuthException] is narrowed for the same reason -- its message is the useful
/// part and its surrounding object can carry the address that was attempted.
///
/// Everything else is passed through, because an arbitrary error's `toString`
/// is usually the whole diagnostic and withholding it would make failures
/// unreadable for no gain. If a future error type is found to embed user data,
/// narrow it here rather than at each call site.
String safeError(Object error) {
  if (error is PostgrestException) {
    return 'PostgrestException(${error.code ?? 'no-code'}): ${error.message}';
  }
  if (error is AuthException) {
    return 'AuthException(${error.statusCode ?? 'no-status'}): ${error.message}';
  }
  return error.toString();
}
