import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/firebase_service.dart';
import '../../core/services/notification_service.dart';
import '../profile/user_model.dart';

const _loggedInKey = 'brisko_logged_in';

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
  final _google = GoogleSignIn(scopes: const ['email', 'profile']);

  Future<void> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) return;
    final googleAuth = await account.authentication;
    if (googleAuth.idToken == null) {
      throw Exception('Google sign-in failed. Enable the Google provider in Firebase and add your app SHA-1.');
    }
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _fb.auth.signInWithCredential(credential);
    final user = cred.user;
    if (user == null) throw Exception('Google sign-in failed.');
    await _ensureUserRecord(user);
    await NotificationService().registerToken(user.uid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
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
    try {
      final account = await _google.signInSilently().timeout(const Duration(seconds: 6));
      if (account == null) return _fb.auth.currentUser;
      final googleAuth = await account.authentication;
      if (googleAuth.idToken == null) return _fb.auth.currentUser;
      final cred = await _fb.auth.signInWithCredential(
        GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        ),
      );
      final user = cred.user;
      if (user != null) await _ensureUserRecord(user);
      return user ?? _fb.auth.currentUser;
    } catch (_) {
      return _fb.auth.currentUser;
    }
  }

  Future<void> _ensureUserRecord(User user) async {
    final ref = _fb.ref('users/${user.uid}');
    final snap = await ref.get();
    final name = (user.displayName ?? '').trim();
    final email = (user.email ?? '').trim();
    if (!snap.exists) {
      await ref.set({
        'name': name,
        'email': email,
        'phone': '',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      return;
    }
    final updates = <String, dynamic>{};
    final current = snap.value is Map ? Map<dynamic, dynamic>.from(snap.value as Map) : <dynamic, dynamic>{};
    if ((current['name'] ?? '').toString().trim().isEmpty && name.isNotEmpty) {
      updates['name'] = name;
    }
    if ((current['email'] ?? '').toString().trim().isEmpty && email.isNotEmpty) {
      updates['email'] = email;
    }
    if (updates.isNotEmpty) await ref.update(updates);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
    try {
      await _google.signOut();
    } catch (_) {}
    await _fb.auth.signOut();
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
