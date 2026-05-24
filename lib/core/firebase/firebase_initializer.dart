import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_recipes/firebase_options.dart';

class FirebaseInitializer {
  FirebaseInitializer._();

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
