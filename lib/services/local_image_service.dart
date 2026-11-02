import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

// The phone app saves photos as files; the web version saves them in the
// browser. Only one of these two files is compiled, depending on platform.
import 'image_store_io.dart'
    if (dart.library.js_interop) 'image_store_web.dart' as store;

/// Takes photos with the camera or picks them from the gallery, and keeps
/// them on the student's own device:
///
///  * Phone app (Android/iOS): a file in the app's private folder.
///  * Web version: this browser's storage.
///
/// Nothing is uploaded to the cloud. Firestore only stores the file name.
///
/// Keep in mind: the photo only exists on the device that took it. It is
/// gone if the app is uninstalled or the browser data is cleared.
class LocalImageService {
  LocalImageService._();
  static final LocalImageService instance = LocalImageService._();

  final ImagePicker _picker = ImagePicker();

  /// Opens the camera or the gallery. Returns null if the student cancels.
  /// The returned file is temporary until [saveToDevice] is called.
  Future<XFile?> pick(ImageSource source) {
    return _picker.pickImage(
      source: source,
      // Browser storage is small, so web photos are kept smaller.
      maxWidth: kIsWeb ? 1024 : 1600,
      maxHeight: kIsWeb ? 1024 : 1600,
      imageQuality: kIsWeb ? 70 : 75,
    );
  }

  /// Saves a picked photo on this device and returns the file name to store
  /// in Firestore.
  Future<String> saveToDevice(XFile picked) => store.savePhoto(picked);

  /// Loads a saved photo by file name. Returns null if it isn't on this
  /// device.
  Future<Uint8List?> load(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return null;
    try {
      return await store.loadPhoto(fileName);
    } catch (error) {
      debugPrint('Could not load photo $fileName: $error');
      return null;
    }
  }

  Future<void> delete(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return;
    try {
      await store.deletePhoto(fileName);
    } catch (_) {
      // Not important if the photo is already gone.
    }
  }
}
