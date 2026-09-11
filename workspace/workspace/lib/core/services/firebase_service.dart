import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  FirebaseService._();
  static final instance = FirebaseService._();

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseDatabase get db => FirebaseDatabase.instance;

  DatabaseReference ref(String path) => db.ref(path);

  Future<void> enablePersistence() async {
    db.setPersistenceEnabled(true);
  }
}
