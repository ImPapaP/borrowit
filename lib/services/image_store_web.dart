// Web version: photos are saved in this browser's storage on the student's
// own device (nothing is uploaded). Browsers allow about 5 MB per website,
// which is room for roughly 20-30 photos at the size LocalImageService picks.

import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

String _key(String fileName) => 'request_photo_$fileName';

class PhotoStorageFullException implements Exception {
  @override
  String toString() =>
      'This browser has no room left for photos. Cancel an old request that '
      'has a photo, or submit this one without a photo.';
}

Future<String> savePhoto(XFile picked) async {
  final bytes = await picked.readAsBytes();
  final fileName = 'request_${DateTime.now().millisecondsSinceEpoch}.jpg';
  try {
    await _prefs.setString(_key(fileName), base64Encode(bytes));
  } catch (_) {
    throw PhotoStorageFullException();
  }
  return fileName;
}

Future<Uint8List?> loadPhoto(String fileName) async {
  final encoded = await _prefs.getString(_key(fileName));
  if (encoded == null || encoded.isEmpty) return null;
  return base64Decode(encoded);
}

Future<void> deletePhoto(String fileName) async {
  await _prefs.remove(_key(fileName));
}
