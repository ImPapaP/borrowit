// Applies the Android and iOS settings BorrowIT needs for notifications and
// the camera. Run it once, after `flutter create .` (see README.md):
//
//   dart run tool/setup_platforms.dart
//
// Running it again is safe; it skips anything that's already done.

import 'dart:io';

final List<String> problems = [];

void main() {
  stdout.writeln('Setting up Android...');
  _android();
  stdout.writeln('Setting up iOS...');
  _ios();

  if (problems.isEmpty) {
    stdout.writeln('\nDone. Android and iOS settings are ready.');
  } else {
    stdout.writeln('\nFinished, but these steps need to be done by hand '
        '(see "Manual platform setup" in README.md):');
    for (final problem in problems) {
      stdout.writeln('  - $problem');
    }
    exitCode = 1;
  }
}

// ------------------------------------------------------------------ Android

void _android() {
  final kotlinScript = File('android/app/build.gradle.kts');
  final groovyScript = File('android/app/build.gradle');
  if (kotlinScript.existsSync()) {
    _patchGradle(kotlinScript, kotlin: true);
  } else if (groovyScript.existsSync()) {
    _patchGradle(groovyScript, kotlin: false);
  } else {
    problems.add('android/app/build.gradle.kts not found. '
        'Run "flutter create ." in the project folder first.');
    return;
  }
  _patchManifest(File('android/app/src/main/AndroidManifest.xml'));
}

void _patchGradle(File file, {required bool kotlin}) {
  var text = file.readAsStringSync();
  final original = text;

  // 1. Java 17, as flutter_local_notifications asks for.
  text = text.replaceAll(
    RegExp(r'JavaVersion\.VERSION_\w+'),
    'JavaVersion.VERSION_17',
  );
  text = text.replaceAll(RegExp(r'JvmTarget\.JVM_\w+'), 'JvmTarget.JVM_17');
  text = text.replaceAll(
    RegExp(r'''jvmTarget\s*=\s*["'][0-9.]+["']'''),
    'jvmTarget = "17"',
  );

  // 2. Core library desugaring (needed by flutter_local_notifications).
  if (!text.toLowerCase().contains('corelibrarydesugaringenabled')) {
    final line = kotlin
        ? 'isCoreLibraryDesugaringEnabled = true'
        : 'coreLibraryDesugaringEnabled true';
    final updated = _insertAfter(text, RegExp(r'compileOptions\s*\{'), '\n        $line');
    if (updated == null) {
      problems.add('Add "$line" inside compileOptions { } in ${file.path}');
    } else {
      text = updated;
    }
  }

  // 3. minSdk 24 (needed by Firebase and flutter_local_notifications).
  final hasMinSdk = RegExp(r'minSdk\s*=|minSdkVersion\s').hasMatch(text);
  if (hasMinSdk) {
    text = text.replaceAll(RegExp(r'minSdk\s*=\s*[^\n]+'), 'minSdk = 24');
    text = text.replaceAll(RegExp(r'minSdkVersion\s+[^\n]+'), 'minSdkVersion 24');
  } else {
    problems.add('Set minSdk = 24 inside defaultConfig { } in ${file.path}');
  }

  // 4. multiDex.
  if (!text.contains('multiDexEnabled')) {
    final line = kotlin ? 'multiDexEnabled = true' : 'multiDexEnabled true';
    final updated = _insertAfter(text, RegExp(r'defaultConfig\s*\{'), '\n        $line');
    if (updated == null) {
      problems.add('Add "$line" inside defaultConfig { } in ${file.path}');
    } else {
      text = updated;
    }
  }

  // 5. The desugaring library.
  if (!text.contains('desugar_jdk_libs')) {
    final dependency = kotlin
        ? 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")'
        : "coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'";
    text = '${text.trimRight()}\n\ndependencies {\n    $dependency\n}\n';
  }

  if (text != original) {
    file.writeAsStringSync(text);
    stdout.writeln('  updated ${file.path}');
  } else {
    stdout.writeln('  ${file.path} already set up');
  }
}

void _patchManifest(File file) {
  if (!file.existsSync()) {
    problems.add('${file.path} not found.');
    return;
  }
  var text = file.readAsStringSync();
  final original = text;

  const permissions = [
    'android.permission.RECEIVE_BOOT_COMPLETED',
    'android.permission.SCHEDULE_EXACT_ALARM',
  ];
  for (final permission in permissions) {
    if (text.contains(permission)) continue;
    final index = text.indexOf('<application');
    if (index == -1) {
      problems.add('Add <uses-permission android:name="$permission"/> to ${file.path}');
      continue;
    }
    final lineStart = text.lastIndexOf('\n', index) + 1;
    text = '${text.substring(0, lineStart)}'
        '    <uses-permission android:name="$permission"/>\n'
        '${text.substring(lineStart)}';
  }

  if (!text.contains('ScheduledNotificationReceiver')) {
    final index = text.lastIndexOf('</application>');
    if (index == -1) {
      problems.add('Add the notification receivers to ${file.path}');
    } else {
      const receivers = '''
        <!-- Scheduled reminders (flutter_local_notifications) -->
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
''';
      final lineStart = text.lastIndexOf('\n', index) + 1;
      text = text.substring(0, lineStart) + receivers + text.substring(lineStart);
    }
  }

  if (text != original) {
    file.writeAsStringSync(text);
    stdout.writeln('  updated ${file.path}');
  } else {
    stdout.writeln('  ${file.path} already set up');
  }
}

// ---------------------------------------------------------------------- iOS

void _ios() {
  final plist = File('ios/Runner/Info.plist');
  if (!plist.existsSync()) {
    stdout.writeln('  no ios folder - skipped (fine if you only build for Android)');
    return;
  }

  var text = plist.readAsStringSync();
  final original = text;
  const entries = {
    'NSCameraUsageDescription':
        'BorrowIT uses the camera so you can attach a photo to a borrow request.',
    'NSPhotoLibraryUsageDescription':
        'BorrowIT lets you attach a photo from your library to a borrow request.',
  };
  for (final entry in entries.entries) {
    if (text.contains('<key>${entry.key}</key>')) continue;
    final index = text.lastIndexOf('</dict>');
    if (index == -1) {
      problems.add('Add ${entry.key} to ${plist.path}');
      continue;
    }
    final lineStart = text.lastIndexOf('\n', index) + 1;
    text = '${text.substring(0, lineStart)}'
        '\t<key>${entry.key}</key>\n'
        '\t<string>${entry.value}</string>\n'
        '${text.substring(lineStart)}';
  }
  if (text != original) {
    plist.writeAsStringSync(text);
    stdout.writeln('  updated ${plist.path}');
  }

  final delegate = File('ios/Runner/AppDelegate.swift');
  if (!delegate.existsSync()) return;
  var swift = delegate.readAsStringSync();
  if (swift.contains('UNUserNotificationCenter')) {
    stdout.writeln('  ${delegate.path} already set up');
    return;
  }
  final updated = _insertAfter(
    swift,
    RegExp(r'didFinishLaunchingWithOptions[^{]*\{'),
    '\n    UNUserNotificationCenter.current().delegate = '
        'self as? UNUserNotificationCenterDelegate',
  );
  if (updated == null) {
    problems.add('Add "UNUserNotificationCenter.current().delegate = self as? '
        'UNUserNotificationCenterDelegate" to didFinishLaunchingWithOptions '
        'in ${delegate.path}');
    return;
  }
  swift = updated;
  if (!swift.contains('import UserNotifications')) {
    swift = 'import UserNotifications\n$swift';
  }
  delegate.writeAsStringSync(swift);
  stdout.writeln('  updated ${delegate.path}');
}

// ------------------------------------------------------------------ helpers

/// Inserts [insertion] right after the first match of [pattern], or returns
/// null if there's no match.
String? _insertAfter(String text, RegExp pattern, String insertion) {
  final match = pattern.firstMatch(text);
  if (match == null) return null;
  return text.substring(0, match.end) + insertion + text.substring(match.end);
}
