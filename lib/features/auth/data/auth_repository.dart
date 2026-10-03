import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';

class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      if (response.user == null) {
        throw const AuthError('Sign up failed. Please try again.');
      }
    } on AuthException catch (e) {
      throw AuthError(e.message);
    } catch (_) {
      throw const AuthError();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthError(e.message);
    } catch (_) {
      throw const NetworkError();
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      throw const AuthError('Sign out failed.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw AuthError(e.message);
    } catch (_) {
      throw const NetworkError();
    }
  }
}
