import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trulura/services/database_service/database_service.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  SupabaseClient? get _clientOrNull {
    if (!DatabaseService.instance.isInitialized) return null;
    return Supabase.instance.client;
  }

  User? get currentAuthUser => _clientOrNull?.auth.currentUser;

  bool get isSignedIn => currentAuthUser != null;

  Stream<AuthState> get onAuthStateChange {
    final client = _clientOrNull;
    if (client == null) return const Stream.empty();
    return client.auth.onAuthStateChange;
  }

  Future<AuthResponse> signUpWithEmail({required String email, required String password, required String name}) async {
    final client = _clientOrNull;
    if (client == null) throw StateError('Supabase not initialized');
    try {
      // Auth-only setup: do not touch `public.profiles` / mirror tables.
      return await client.auth.signUp(email: email, password: password, data: {'name': name});
    } catch (e) {
      debugPrint('AuthService.signUpWithEmail failed: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signInWithEmail({required String email, required String password}) async {
    final client = _clientOrNull;
    if (client == null) throw StateError('Supabase not initialized');
    try {
      return await client.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      debugPrint('AuthService.signInWithEmail failed: $e');
      rethrow;
    }
  }

  Future<void> resendSignupConfirmationEmail({required String email}) async {
    final client = _clientOrNull;
    if (client == null) throw StateError('Supabase not initialized');
    try {
      await client.auth.resend(type: OtpType.signup, email: email);
    } catch (e) {
      debugPrint('AuthService.resendSignupConfirmationEmail failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    final client = _clientOrNull;
    if (client == null) return;
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('AuthService.signOut failed: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordReset({required String email}) async {
    final client = _clientOrNull;
    if (client == null) throw StateError('Supabase not initialized');
    try {
      await client.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('AuthService.sendPasswordReset failed: $e');
      rethrow;
    }
  }
}
