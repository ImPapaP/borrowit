import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    // Most likely `flutterfire configure` hasn't been run yet.
    runApp(SetupErrorApp(error: error.toString()));
    return;
  }

  await NotificationService.instance.init();

  runApp(const BorrowItApp());
}
