// Phone app (Android/iOS): photos are saved as files in the app's private
// documents folder, in a subfolder called request_images.
// No storage permission is needed for this folder.

import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<Directory> _photosDir() async {
  final documents = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(documents.path, 'request_images'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

Future<File> _fileFor(String fileName) async {
  final dir = await _photosDir();
  return File(p.join(dir.path, p.basename(fileName)));
}

/// Copies the picked photo out of the picker's temporary folder (which the
/// system may clear) into the app's own folder.
Future<String> savePhoto(XFile picked) async {
  var extension = p.extension(picked.name.isNotEmpty ? picked.name : picked.path);
  extension = extension.toLowerCase();
  if (extension.isEmpty) extension = '.jpg';
  final fileName = 'request_${DateTime.now().millisecondsSinceEpoch}$extension';
  final file = await _fileFor(fileName);
  await picked.saveTo(file.path);
  return fileName;
}

Future<Uint8List?> loadPhoto(String fileName) async {
  final file = await _fileFor(fileName);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}

Future<void> deletePhoto(String fileName) async {
  final file = await _fileFor(fileName);
  if (await file.exists()) await file.delete();
}

/// Downloads are a website feature. The phone app already keeps the photo
/// as a file on the phone, so there is nothing extra to do here.
bool downloadCopy(Uint8List bytes, String downloadName, String mimeType) =>
    false;
