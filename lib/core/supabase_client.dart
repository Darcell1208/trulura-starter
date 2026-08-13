import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trulura/services/database_service/database_service.dart';

/// Shared Supabase client accessor.
///
/// This keeps feature/services code decoupled from the bootstrap details.
///
/// Throws if Supabase hasn't been initialized yet.
SupabaseClient get supabase => DatabaseService.instance.client;
