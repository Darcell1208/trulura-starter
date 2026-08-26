import 'package:flutter/foundation.dart';
import 'package:trulura/models/identity/identity_core.dart';
import 'package:trulura/services/auth_service/auth_service.dart';
import 'package:trulura/services/database_service/database_service.dart';

/// Persistence for [IdentityCore]. No emotional logic, no UI logic.
class IdentityCoreRepository {
  bool get _supabaseReady => DatabaseService.instance.isInitialized;

  Future<IdentityCore?> getForCurrentUser() async {
    final userId = AuthService.instance.currentAuthUser?.id;
    if (userId == null || !_supabaseReady) return null;

    try {
      final row = await DatabaseService.instance.client
          .from('identity_core')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return null;
      return IdentityCore.fromJson(row);
    } catch (e) {
      debugPrint('IdentityCoreRepository.getForCurrentUser failed: $e');
      return null;
    }
  }

  Future<IdentityCore?> save(IdentityCore identityCore) async {
    if (!_supabaseReady) return null;

    try {
      final row = await DatabaseService.instance.client
          .from('identity_core')
          .upsert(identityCore.toJson())
          .select()
          .single();
      return IdentityCore.fromJson(row);
    } catch (e) {
      debugPrint('IdentityCoreRepository.save failed: $e');
      return null;
    }
  }
}
