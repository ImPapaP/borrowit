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

  /// Whether a copy can be downloaded to the device's Downloads folder.
  /// Website only; the phone app already keeps photos as files.
  bool get canSaveToDownloads => kIsWeb;

  /// Website only: downloads a copy of the photo as a file named like
  /// `BorrowIT_Laptop_2026-11-05.jpg`. Returns false if that isn't possible.
  bool saveCopyToDownloads(
    Uint8List bytes, {
    required String equipmentName,
    DateTime? date,
  }) {
    if (!canSaveToDownloads) return false;
    try {
      final (extension, mimeType) = _imageType(bytes);
      final name = '${_downloadBaseName(equipmentName, date)}$extension';
      return store.downloadCopy(bytes, name, mimeType);
    } catch (error) {
      debugPrint('Could not download photo: $error');
      return false;
    }
  }

  String _downloadBaseName(String equipmentName, DateTime? date) {
    final item = equipmentName
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final day = date ?? DateTime.now();
    final stamp = '${day.year}-${_two(day.month)}-${_two(day.day)}';
    return item.isEmpty ? 'BorrowIT_$stamp' : 'BorrowIT_${item}_$stamp';
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  /// Works out the image format from the file's first bytes.
  (String, String) _imageType(Uint8List bytes) {
    bool startsWith(List<int> prefix, [int offset = 0]) {
      if (bytes.length < offset + prefix.length) return false;
      for (var i = 0; i < prefix.length; i++) {
        if (bytes[offset + i] != prefix[i]) return false;
      }
      return true;
    }

    if (startsWith(const [0x89, 0x50, 0x4E, 0x47])) return ('.png', 'image/png');
    if (startsWith(const [0x47, 0x49, 0x46])) return ('.gif', 'image/gif');
    if (startsWith(const [0x52, 0x49, 0x46, 0x46]) &&
        startsWith(const [0x57, 0x45, 0x42, 0x50], 8)) {
      return ('.webp', 'image/webp');
    }
    return ('.jpg', 'image/jpeg');
  }
}
