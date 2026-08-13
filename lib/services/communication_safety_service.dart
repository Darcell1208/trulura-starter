import 'package:flutter/foundation.dart';

/// Section 9: In-interaction protections.
///
/// This is a local-first message safety layer:
/// - basic content filtering (slurs/explicit requests)
/// - rate limiting (anti-spam)
///
/// Keep it deterministic and non-invasive.
class CommunicationSafetyService {
  static final RegExp _explicit = RegExp(r'\b(nude|nudes|onlyfans|porn|sex)\b', caseSensitive: false);
  static final RegExp _money = RegExp(r'\b(cash|crypto|bitcoin|wire|transfer|deposit|fee)\b', caseSensitive: false);
  static final RegExp _email = RegExp(r'\b[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}\b');
  static final RegExp _phone = RegExp(r'(?:\+?\d{1,3}[\s.-]?)?(?:\(\d{2,4}\)[\s.-]?)?\d{3,4}[\s.-]?\d{3,4}');
  static final RegExp _address = RegExp(r'\b(\d{1,5}\s+[A-Za-z0-9 .-]{3,}\s+(street|st|avenue|ave|road|rd|blvd|boulevard|lane|ln|drive|dr))\b', caseSensitive: false);
  static final RegExp _selfHarm = RegExp(r'\b(suicide|kill myself|end it|self[- ]?harm|hurt myself|i want to die)\b', caseSensitive: false);

  final Map<String, List<DateTime>> _recentByChat = <String, List<DateTime>>{};

  CommunicationCheckResult checkOutgoing({required String chatId, required String text}) {
    try {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return const CommunicationCheckResult.blocked('Message is empty.');

      // Rate limit: max 8 messages / 20 seconds per chat.
      final now = DateTime.now();
      final list = (_recentByChat[chatId] ?? <DateTime>[]).where((t) => now.difference(t).inSeconds <= 20).toList();
      list.add(now);
      _recentByChat[chatId] = list;
      if (list.length > 8) return const CommunicationCheckResult.blocked('Slow down a bit — let the conversation breathe.');

      final flags = <TruMessageFlag>[];
      if (_explicit.hasMatch(trimmed)) flags.add(TruMessageFlag.sexual);
      if (_money.hasMatch(trimmed)) flags.add(TruMessageFlag.money);
      if (_email.hasMatch(trimmed) || _phone.hasMatch(trimmed) || _address.hasMatch(trimmed)) flags.add(TruMessageFlag.possibleDoxxing);
      if (_selfHarm.hasMatch(trimmed)) flags.add(TruMessageFlag.crisis);

      if (flags.isEmpty) return const CommunicationCheckResult.ok();

      // We do not fully block by default; we return "needs confirmation".
      return CommunicationCheckResult.needsConfirm(flags);
    } catch (e) {
      debugPrint('CommunicationSafetyService.checkOutgoing failed: $e');
      return const CommunicationCheckResult.ok();
    }
  }
}

enum TruMessageFlag { sexual, money, possibleDoxxing, crisis }

extension TruMessageFlagX on TruMessageFlag {
  String get label {
    switch (this) {
      case TruMessageFlag.sexual:
        return 'sexual content';
      case TruMessageFlag.money:
        return 'money/fees';
      case TruMessageFlag.possibleDoxxing:
        return 'personal info';
      case TruMessageFlag.crisis:
        return 'crisis language';
    }
  }
}

@immutable
class CommunicationCheckResult {
  final bool allowed;
  final bool needsUserConfirm;
  final String? blockReason;
  final List<TruMessageFlag> flags;

  const CommunicationCheckResult._({required this.allowed, required this.needsUserConfirm, required this.flags, this.blockReason});
  const CommunicationCheckResult.ok() : this._(allowed: true, needsUserConfirm: false, flags: const []);
  const CommunicationCheckResult.blocked(String reason) : this._(allowed: false, needsUserConfirm: false, flags: const [], blockReason: reason);
  const CommunicationCheckResult.needsConfirm(List<TruMessageFlag> flags) : this._(allowed: true, needsUserConfirm: true, flags: flags);

  String get prompt {
    if (!needsUserConfirm) return '';
    final parts = flags.map((f) => f.label).toList(growable: false);
    return 'This message may include ${parts.join(' + ')}. Send anyway?';
  }
}
