// Firebase settings for BorrowIT.
//
// WEB VERSION (Render):
//   Paste your Firebase web app's config into the `web` section below and
//   commit. Find it in Firebase console > Project settings (gear icon) >
//   General > Your apps > your Web app > "SDK setup and configuration" >
//   Config. These values are meant to be public; your data is protected by
//   firestore.rules.
//
// PHONE APP (Android/iOS):
//   Run `flutterfire configure` on your computer and select android, ios
//   and web. It rewrites this whole file with settings for every platform.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      if (web.apiKey.startsWith('PASTE')) {
        throw UnsupportedError(
          'Firebase is not connected yet.\n\n'
          'Open lib/firebase_options.dart in the GitHub repo, paste your '
          'Firebase web config into the "web" section, and commit. Render '
          'rebuilds the site automatically in a few minutes.',
        );
      }
      return web;
    }
    throw UnsupportedError(
      'Firebase is not configured for this device yet.\n\n'
      'Open a terminal in the project folder and run:\n'
      '  flutterfire configure\n\n'
      'Then restart the app.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'PASTE_API_KEY_HERE',
    authDomain: 'PASTE_AUTH_DOMAIN_HERE',
    projectId: 'PASTE_PROJECT_ID_HERE',
    storageBucket: 'PASTE_STORAGE_BUCKET_HERE',
    messagingSenderId: 'PASTE_MESSAGING_SENDER_ID_HERE',
    appId: 'PASTE_APP_ID_HERE',
  );
}
