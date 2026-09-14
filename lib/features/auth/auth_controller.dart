import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// OLD SOCIAL (GOOGLE) LOGIN — disabled in favour of mobile OTP. Kept for reference.
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/firebase_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/otp_auth_service.dart';
import '../location/location_controller.dart';
import '../profile/user_model.dart';

const _loggedInKey = 'brisko_logged_in';

final otpAuthServiceProvider = Provider<OtpAuthService>((ref) => OtpAuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final sessionRestoreProvider = FutureProvider<User?>((ref) async {
  final splashHold = Future<void>.delayed(const Duration(milliseconds: 900));
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    try {
      user = await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(seconds: 2),
        onTimeout: () => FirebaseAuth.instance.currentUser,
      );
    } catch (_) {
      user = FirebaseAuth.instance.currentUser;
    }
  }
  if (user == null) {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    user = FirebaseAuth.instance.currentUser;
  }
  user ??= await ref.read(authControllerProvider).restoreSession();
  if (user != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
  }
  await splashHold;
  return user ?? FirebaseAuth.instance.currentUser;
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream.value(null);
  return FirebaseService.instance.ref('users/${auth.uid}').onValue.map((event) {
    final val = event.snapshot.value;
    if (val is Map) return UserModel.fromMap(auth.uid, Map<dynamic, dynamic>.from(val));
    return null;
  });
});

final authControllerProvider = Provider<AuthController>((ref) => AuthController(ref));

class AuthController {
  AuthController(this._ref);
  final Ref _ref;
  final _fb = FirebaseService.instance;

  // OLD SOCIAL (GOOGLE) LOGIN — disabled. Only ONE active auth flow (mobile OTP)
  // is allowed, so this is left commented until the OTP flow is fully verified.
  //
  // final _google = GoogleSignIn(scopes: const ['email', 'profile']);
  //
  // Future<void> signInWithGoogle() async {
  //   final account = await _google.signIn();
  //   if (account == null) return;
  //   final googleAuth = await account.authentication;
  //   if (googleAuth.idToken == null) {
  //     throw Exception('Google sign-in failed. Enable the Google provider in Firebase and add your app SHA-1.');
  //   }
  //   final credential = GoogleAuthProvider.credential(
  //     accessToken: googleAuth.accessToken,
  //     idToken: googleAuth.idToken,
  //   );
  //   final cred = await _fb.auth.signInWithCredential(credential);
  //   final user = cred.user;
  //   if (user == null) throw Exception('Google sign-in failed.');
  //   await _ensureUserRecord(user);
  //   await NotificationService().registerToken(user.uid);
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setBool(_loggedInKey, true);
  //   _ref.read(locationControllerProvider.notifier).clearForNewLogin();
  // }

  /// Signs into Firebase using the custom token minted by the PHP backend
  /// after a successful OTP verification.
  Future<User> signInWithCustomToken(String customToken, {String phone = ''}) async {
    final cred = await _fb.auth.signInWithCustomToken(customToken);
    final user = cred.user;
    if (user == null) throw Exception('Sign in failed. Please try again.');
    await _ensurePhoneUserRecord(user, phone);
    await NotificationService().registerToken(user.uid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
    _ref.read(locationControllerProvider.notifier).clearForNewLogin();
    return user;
  }

  /// Called from the register screen on first login to capture the user's name.
  Future<void> registerProfile(String name) async {
    final uid = _fb.auth.currentUser?.uid;
    if (uid == null) return;
    final trimmed = name.trim();
    await _fb.ref('users/$uid').update({
      'name': trimmed,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
    if (trimmed.isNotEmpty) {
      await _fb.auth.currentUser?.updateDisplayName(trimmed);
    }
  }

  Future<User?> restoreSession() async {
    var existing = _fb.auth.currentUser;
    if (existing != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loggedInKey, true);
      return existing;
    }
    await Future<void>.delayed(const Duration(milliseconds: 350));
    existing = _fb.auth.currentUser;
    if (existing != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loggedInKey, true);
      return existing;
    }
    // OLD SOCIAL (GOOGLE) SILENT RESTORE — disabled with the Google flow.
    // Firebase persists the custom-token session on its own, so no silent
    // provider restore is needed anymore.
    //
    // try {
    //   final account = await _google.signInSilently().timeout(const Duration(seconds: 6));
    //   ...
    // } catch (_) {
    //   return _fb.auth.currentUser;
    // }
    return _fb.auth.currentUser;
  }

  Future<void> _ensurePhoneUserRecord(User user, String phone) async {
    final ref = _fb.ref('users/${user.uid}');
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'name': '',
      'email': '',
      'phone': phone,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
    // OLD SOCIAL (GOOGLE) LOGOUT — disabled with the Google flow.
    // try {
    //   await _google.signOut();
    // } catch (_) {}
    // Best-effort server notification; never block local sign-out on it.
    unawaited(_ref.read(otpAuthServiceProvider).logout().catchError((_) {}));
    await _fb.auth.signOut();
    _ref.read(locationControllerProvider.notifier).clearForNewLogin();
    _ref.invalidate(sessionRestoreProvider);
  }

  Future<void> updateProfile({required String name, String? email, String? phone}) async {
    final uid = _fb.auth.currentUser?.uid;
    if (uid == null) return;
    final updates = <String, dynamic>{'name': name.trim()};
    if (email != null) updates['email'] = email.trim();
    if (phone != null) updates['phone'] = phone.trim();
    await _fb.ref('users/$uid').update(updates);
    await _fb.auth.currentUser?.updateDisplayName(name.trim());
  }

  String? get currentUid => _fb.auth.currentUser?.uid;
}
