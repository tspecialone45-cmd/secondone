import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/errors/app_exception.dart';

class StorageRepository {
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  StorageRepository({
    FirebaseStorage? storage,
    ImagePicker? picker,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  /// Picks an image from camera or gallery
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      throw AppException('फोटो निवडताना त्रुटी आली: ${e.toString()}');
    }
  }

  /// Uploads user profile photo to Firebase Storage and returns download URL
  Future<String> uploadProfilePhoto({
    required String uid,
    required File imageFile,
  }) async {
    try {
      final ref = _storage.ref().child('profile_photos').child('$uid.jpg');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = await ref.putFile(imageFile, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw AppException('फोटो अपलोड करताना त्रुटी आली: ${e.toString()}');
    }
  }
}
