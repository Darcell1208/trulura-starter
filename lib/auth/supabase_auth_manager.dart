import 'package:flutter/material.dart';
import 'package:trulura/auth/auth_manager.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/auth_service/auth_service.dart';
import 'package:trulura/services/user_service.dart';

/// Supabase-backed implementation of [AuthManager].
///
/// This gives the app a single, consistent contract for auth flows while we
/// build out the rest of Phase-1.
class SupabaseAuthManager extends AuthManager with EmailSignInManager {
  @override
  Future<User?> signInWithEmail(BuildContext context, String email, String password) async {
    try {
      await AuthService.instance.signInWithEmail(email: email, password: password);
      return await UserService().getCurrentUser();
    } catch (e) {
      debugPrint('SupabaseAuthManager.signInWithEmail failed: $e');
      rethrow;
    }
  }

  @override
  Future<User?> createAccountWithEmail(BuildContext context, String email, String password) async {
    try {
      await AuthService.instance.signUpWithEmail(email: email, password: password, name: email.split('@').first);
      return await UserService().getCurrentUser();
    } catch (e) {
      debugPrint('SupabaseAuthManager.createAccountWithEmail failed: $e');
      rethrow;
    }
  }

  @override
  Future signOut() => AuthService.instance.signOut();

  @override
  Future deleteUser(BuildContext context) async {
    // Requires Admin API / service role key. Not supported client-side.
    throw UnimplementedError('Account deletion must be implemented server-side (edge function).');
  }

  @override
  Future updateEmail({required String email, required BuildContext context}) async {
    throw UnimplementedError('Email update not implemented yet.');
  }

  @override
  Future resetPassword({required String email, required BuildContext context}) => AuthService.instance.sendPasswordReset(email: email);

  @override
  Future<void> sendEmailVerification({required User user}) async {
    // Supabase sends verification email automatically if enabled in Auth settings.
  }

  @override
  Future<void> refreshUser({required User user}) async {
    await UserService().getCurrentUser();
  }
}
