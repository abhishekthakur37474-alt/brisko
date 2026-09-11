import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    final cred = await _fb.auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final uid = cred.user!.uid;
    await cred.user!.updateDisplayName(name);
    await _fb.ref('users/$uid').set({
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    await NotificationService().registerToken(uid);
  }

  Future<void> login({required String email, required String password}) async {
    final cred = await _fb.auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    await NotificationService().registerToken(cred.user!.uid);
  }

  Future<void> forgotPassword(String email) async {
    await _fb.auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() => _fb.auth.signOut();

  Future<void> updateProfile({required String name, required String phone}) async {
    final uid = _fb.auth.currentUser?.uid;
    if (uid == null) return;
    await _fb.ref('users/$uid').update({'name': name.trim(), 'phone': phone.trim()});
    await _fb.auth.currentUser?.updateDisplayName(name.trim());
  }
}
