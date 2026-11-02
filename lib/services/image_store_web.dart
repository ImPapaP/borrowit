// Web version: photos are saved in this browser's storage on the student's
// own device (nothing is uploaded). Browsers allow about 5 MB per website,
// which is room for roughly 20-30 photos at the size LocalImageService picks.
//
// A copy can also be downloaded as a file, so it shows up in the device's
// Downloads folder (and in Files / Gallery on phones).

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

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

/// Downloads [bytes] as a file named [downloadName]. The browser saves it to
/// the device's Downloads folder (some browsers ask first).
bool downloadCopy(Uint8List bytes, String downloadName, String mimeType) {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = downloadName
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  // Give the browser time to start the download before freeing the data.
  Timer(const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
  return true;
}
