import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trulura/supabase/supabase_config.dart';

/// Central database bootstrap.
///
/// Trulura now uses **Supabase** as the primary backend (Auth + Postgres).
/// This service is intentionally small: it only owns initialization and the
/// shared [SupabaseClient] access point.
class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  SupabaseClient get client {
    if (!_initialized) {
      throw StateError('DatabaseService not initialized. Call initialize() first.');
    }
    return Supabase.instance.client;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await SupabaseConfig.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('DatabaseService.initialize failed: $e');
      rethrow;
    }
  }
}
