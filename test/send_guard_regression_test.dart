import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural guard for Build Status known issue 38: the retry path bypassed
/// every send check.
///
/// **What this proves and what it does not.** These are source-level
/// assertions, not behavioural ones. They cannot show that the guards are
/// *correct* — only that both send paths run them and that delivery happens in
/// exactly one place. A behavioural test would need ChatThreadScreen's whole
/// dependency set (safety centre prefs, comms safety, AuraShield, blocks, sync
/// match, chat service) stubbed, which is a much larger piece of work and is
/// recorded as still outstanding rather than quietly skipped.
///
/// The invariant is worth pinning even so, because the original defect was not
/// a wrong check — it was a second code path that had no checks at all, added
/// later and never reconciled. That is a drift failure, and drift is exactly
/// what a structural test catches.
void main() {
  final source =
      File('lib/screens/chat/chat_thread_screen.dart').readAsStringSync();

  String bodyOf(String signature) {
    final start = source.indexOf(signature);
    expect(start, greaterThan(-1), reason: '$signature not found');
    // Crude but sufficient: read to the next top-level method declaration.
    final rest = source.substring(start + signature.length);
    final end = rest.indexOf('\n  Future<');
    return end == -1 ? rest : rest.substring(0, end);
  }

  test('delivery happens in exactly one place', () {
    // saveMessage is the moment a message leaves the device. If it appears in
    // more than one method, a caller can reach it without passing the guards —
    // which is precisely how _retryPending came to bypass them.
    final calls = '_chatService.saveMessage('.allMatches(source).length;
    expect(calls, 1,
        reason: 'saveMessage must be called only from _deliver. Found $calls '
            'call sites; a second one can bypass _passesSendGuards.');
  });

  test('_retryPending runs the send guards before delivering', () {
    final body = bodyOf('Future<void> _retryPending(String tempId) async {');
    expect(body.contains('_passesSendGuards'), isTrue,
        reason: 'Retry must run the same checks as the first attempt. '
            'Known issue 38: it previously ran none, so a message refused for '
            'a paused chat, a safety flag or a block was delivered by tapping '
            'Retry.');
    // The guard must come before delivery, not after it.
    final guardAt = body.indexOf('_passesSendGuards');
    final deliverAt = body.indexOf('_deliver(');
    expect(deliverAt, greaterThan(-1), reason: '_retryPending must deliver');
    expect(guardAt, lessThan(deliverAt),
        reason: 'the guard must run before the message is delivered');
  });

  test('_sendMessage runs the send guards before delivering', () {
    final body = bodyOf('Future<void> _sendMessage() async {');
    final guardAt = body.indexOf('_passesSendGuards');
    final deliverAt = body.indexOf('_deliver(');
    expect(guardAt, greaterThan(-1));
    expect(deliverAt, greaterThan(guardAt));
  });

  test('the guard still covers pause, block and the safety filter', () {
    final body = bodyOf('Future<bool> _passesSendGuards(String text) async {');
    // Named individually so that deleting any one of them fails loudly rather
    // than silently narrowing what "guarded" means.
    expect(body.contains("== 'paused'"), isTrue,
        reason: 'paused-chat check missing from the guard');
    expect(body.contains('_blocks.isBlocked'), isTrue,
        reason: 'block check missing from the guard');
    expect(body.contains('messageFilteringEnabled'), isTrue,
        reason: 'comms safety filter missing from the guard');
  });
}
