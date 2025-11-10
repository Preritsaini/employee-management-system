import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadEmployeePhoto(File imageFile, String employeeId) async {
    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist at path: ${imageFile.path}');
      }
      
      // Check file size (max 10MB)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Image file is too large. Maximum size is 10MB.');
      }
      
      Reference ref = _storage.ref().child('employee_photos/$employeeId.jpg');
      
      // Set metadata
      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'employeeId': employeeId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      UploadTask uploadTask = ref.putFile(imageFile, metadata);
      
      // Wait for upload to complete and check for errors
      TaskSnapshot snapshot = await uploadTask;
      
      // Check upload state
      if (snapshot.state == TaskState.success) {
        String downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } else {
        // Get error details if available
        String errorDetails = '';
        if (snapshot.state == TaskState.error) {
          errorDetails = ' Upload failed.';
        }
        throw Exception('Upload incomplete. State: ${snapshot.state}.$errorDetails Check Storage rules and bucket setup.');
      }
    } on FirebaseException catch (e) {
      String errorMsg = 'Storage error (${e.code}): ${e.message}';
      if (e.code == 'object-not-found' || e.code == 'unauthorized') {
        errorMsg += '\n\nPlease ensure:\n1. Firebase Storage is enabled\n2. Storage rules are deployed\n3. You are authenticated';
      }
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Failed to upload employee photo: $e');
    }
  }

  Future<String> uploadAttendancePhoto(
      File imageFile, String employeeId, String type) async {
    try {
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage
          .ref()
          .child('attendance_photos/$employeeId/$type/$timestamp.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload attendance photo: $e. Please check Storage permissions.');
    }
  }

  Future<void> deleteEmployeePhoto(String employeeId) async {
    try {
      Reference ref = _storage.ref().child('employee_photos/$employeeId.jpg');
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }
}
