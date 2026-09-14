import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/firebase_service.dart';
import '../auth/auth_controller.dart';
import 'address_model.dart';

final addressesProvider = StreamProvider<List<AddressModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return FirebaseService.instance.ref('users/${user.uid}/addresses').onValue.map((event) {
    final val = event.snapshot.value;
    if (val is! Map) return <AddressModel>[];
    return val.entries
        .map((e) => AddressModel.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
        .toList();
  });
});

final addressControllerProvider = Provider((ref) => AddressController());

class AddressController {
  final _uuid = const Uuid();

  Future<String?> save(AddressModel address) async {
    final uid = FirebaseService.instance.auth.currentUser?.uid;
    if (uid == null) return null;
    final id = address.id.isEmpty ? _uuid.v4() : address.id;
    if (address.isDefault) {
      final snap = await FirebaseService.instance.ref('users/$uid/addresses').get();
      if (snap.value is Map) {
        for (final key in (snap.value as Map).keys) {
          await FirebaseService.instance.ref('users/$uid/addresses/$key/isDefault').set(false);
        }
      }
      await FirebaseService.instance.ref('users/$uid/defaultAddressId').set(id);
    }
    await FirebaseService.instance.ref('users/$uid/addresses/$id').set(address.copyWith().toMap()..['isDefault'] = address.isDefault);
    return id;
  }

  Future<void> delete(String id) async {
    final uid = FirebaseService.instance.auth.currentUser?.uid;
    if (uid == null) return;
    await FirebaseService.instance.ref('users/$uid/addresses/$id').remove();
  }

  Future<void> setDefault(String id) async {
    final uid = FirebaseService.instance.auth.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseService.instance.ref('users/$uid/addresses').get();
    if (snap.value is Map) {
      for (final key in (snap.value as Map).keys) {
        await FirebaseService.instance.ref('users/$uid/addresses/$key/isDefault').set(key.toString() == id);
      }
    }
    await FirebaseService.instance.ref('users/$uid/defaultAddressId').set(id);
  }
}
