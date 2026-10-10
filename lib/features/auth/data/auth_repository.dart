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

  /// Sends OTP to phone. Phone must be in E.164 format e.g. +919876543210
  Future<void> sendPhoneOtp({required String phone}) async {
    try {
      await _client.auth.signInWithOtp(phone: phone);
    } on AuthException catch (e) {
      throw AuthError(e.message);
    } catch (_) {
      throw const NetworkError();
    }
  }

  /// Verifies OTP and signs in. Returns true on success.
  Future<void> verifyPhoneOtp({required String phone, required String token}) async {
    try {
      await _client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
    } on AuthException catch (e) {
      throw AuthError(e.message);
    } catch (_) {
      throw const NetworkError();
    }
  }

  /// Check if phone is already registered (has a profile row).
  Future<bool> isPhoneRegistered({required String phone}) async {
    try {
      final result = await _client
          .from('profiles')
          .select('id')
          .eq('phone', phone)
          .maybeSingle();
      return result != null;
    } catch (_) {
      // If profiles table doesn't exist or query fails, allow attempt
      return true;
    }
  }

  /// Sign up with phone OTP flow – sends OTP for registration.
  Future<void> sendPhoneOtpForSignUp({
    required String phone,
    required String fullName,
  }) async {
    try {
      await _client.auth.signInWithOtp(
        phone: phone,
        data: {'full_name': fullName},
      );
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
