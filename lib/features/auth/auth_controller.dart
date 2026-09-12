import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/services/firebase_service.dart';
import '../../core/services/notification_service.dart';
import '../profile/user_model.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseService.instance.auth.authStateChanges();
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

final authControllerProvider = Provider<AuthController>((ref) => AuthController());

class AuthController {
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
    try {
      await _google.signOut();
    } catch (_) {}
    await _fb.auth.signOut();
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
