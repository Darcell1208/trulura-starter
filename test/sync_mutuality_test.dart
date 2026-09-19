import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/sync_candidate/sync_candidate.dart';
import 'package:trulura/services/sync_service/sync_service.dart';

/// Build Status known issue 40: Sync decided mutual interest with a
/// compatibility-weighted coin flip, then opened a chat on the strength of it.
///
/// The two tests below are the pair that matters. The first proves the
/// fabrication is gone; the second proves the feature was not simply switched
/// off to make the first pass — reciprocity still produces a match when it
/// genuinely exists. A fix that only ever returned `pending` would satisfy the
/// first test and quietly break the product.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a one-sided signal stays pending and creates no match', () async {
    final svc = SyncService();

    final result = await svc.sendSignal(
      userId: 'user-A',
      targetUserId: 'user-B',
      signal: TruInteractionSignal.spark,
    );

    expect(result.status, TruInteractionResultStatus.pending,
        reason: 'user-B has expressed nothing, so there is no mutuality to '
            'report. Previously this was a coin flip that could return '
            'mutual.');
    expect(result.createdMatch, isNull,
        reason: 'no match may be created from one person acting alone');
    expect(result.signalEvent.mutual, isFalse);
    expect(result.signalEvent.createdMatch, isFalse);
  });

  test('a genuinely reciprocal signal is mutual and creates a match', () async {
    final svc = SyncService();

    // B signals A first. Nothing to reciprocate yet.
    final first = await svc.sendSignal(
      userId: 'user-B',
      targetUserId: 'user-A',
      signal: TruInteractionSignal.spark,
    );
    expect(first.status, TruInteractionResultStatus.pending);

    // A now signals B back. That is real reciprocity, and it must register.
    final second = await svc.sendSignal(
      userId: 'user-A',
      targetUserId: 'user-B',
      signal: TruInteractionSignal.spark,
    );

    expect(second.status, TruInteractionResultStatus.mutual,
        reason: 'both people signalled, so the match is earned rather than '
            'invented. The fix reads reciprocity; it does not disable it.');
    expect(second.createdMatch, isNotNull);
    expect(second.createdMatch!.targetUserId, 'user-B');
    expect(second.signalEvent.mutual, isTrue);
  });

  test('reciprocity must be the same kind of signal', () async {
    final svc = SyncService();

    await svc.sendSignal(
      userId: 'user-B',
      targetUserId: 'user-A',
      signal: TruInteractionSignal.glow,
    );
    final result = await svc.sendSignal(
      userId: 'user-A',
      targetUserId: 'user-B',
      signal: TruInteractionSignal.spark,
    );

    expect(result.status, TruInteractionResultStatus.pending,
        reason: 'a Glow is not a returned Spark; matching them would invent '
            'agreement out of two different gestures');
  });
}
