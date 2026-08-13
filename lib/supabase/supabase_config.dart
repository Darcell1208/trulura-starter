import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Supabase configuration for the app.
///
/// IMPORTANT: In Dreamflow, the Supabase project connection/codegen step
/// populates the URL + anon key. Do not change these values unless you
/// intentionally switch projects.
class SupabaseConfig {
  static const String supabaseUrl = 'https://wzcuxarslnbvaosuqduu.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind6Y3V4YXJzbG5idmFvc3VxZHV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI3MjcyNzcsImV4cCI6MjA3ODMwMzI3N30.D2A8ELxDUH4UM1TQ8JYPm7jVVb28RF_Bz83l_rBZGh0';

  /// Dreamflow may inject Supabase credentials via dart-define at runtime.
  ///
  /// We keep the generated constants above as safe fallbacks (and per
  /// Dreamflow guidance we do not modify them).
  static String get resolvedUrl =>
      const String.fromEnvironment('SUPABASE_URL', defaultValue: supabaseUrl);
  static String get resolvedAnonKey =>
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: anonKey);

  static Future<void> initialize() async {
    try {
      final url = resolvedUrl;
      final key = resolvedAnonKey;

      // Never log secrets. This is only a boolean hint for debugging.
      final usingEnv = url != supabaseUrl || key != anonKey;
      debugPrint('SupabaseConfig.initialize (usingEnv=$usingEnv)');

      await Supabase.initialize(url: url, anonKey: key, debug: kDebugMode);
    } catch (e) {
      debugPrint('SupabaseConfig.initialize failed: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
}

/// Generic database service for CRUD operations
class SupabaseService {
  /// Select multiple records from a table
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      dynamic query = SupabaseConfig.client.from(table).select(select ?? '*');

      // Apply filters
      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      return await query;
    } catch (e) {
      throw _handleDatabaseError('select', table, e);
    }
  }

  /// Select a single record from a table
  static Future<Map<String, dynamic>?> selectSingle(
    String table, {
    String? select,
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = SupabaseConfig.client.from(table).select(select ?? '*');

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      return await query.maybeSingle();
    } catch (e) {
      throw _handleDatabaseError('selectSingle', table, e);
    }
  }

  /// Insert a record into a table
  static Future<List<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseConfig.client.from(table).insert(data).select();
    } catch (e) {
      throw _handleDatabaseError('insert', table, e);
    }
  }

  /// Insert multiple records into a table
  static Future<List<Map<String, dynamic>>> insertMultiple(
    String table,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      return await SupabaseConfig.client.from(table).insert(data).select();
    } catch (e) {
      throw _handleDatabaseError('insertMultiple', table, e);
    }
  }

  /// Update records in a table
  static Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = SupabaseConfig.client.from(table).update(data);

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      return await query.select();
    } catch (e) {
      throw _handleDatabaseError('update', table, e);
    }
  }

  /// Delete records from a table
  static Future<void> delete(
    String table, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = SupabaseConfig.client.from(table).delete();

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      await query;
    } catch (e) {
      throw _handleDatabaseError('delete', table, e);
    }
  }

  /// Get direct table reference for complex queries
  static SupabaseQueryBuilder from(String table) =>
      SupabaseConfig.client.from(table);

  /// Handle database errors
  static String _handleDatabaseError(
    String operation,
    String table,
    dynamic error,
  ) {
    if (error is PostgrestException) return 'Failed to $operation from $table: ${error.message}';
    return 'Failed to $operation from $table: ${error.toString()}';
  }
}
