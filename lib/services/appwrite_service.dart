import 'package:appwrite/appwrite.dart';
import 'dart:io';

class AppwriteService {
  static final Client client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1')
    ..setProject('676fc20b003ccf154826');

  static final Storage storage = Storage(client);

  static Future<String> uploadFile({
    required String bucketId,
    required File file,
    required String fileName,
  }) async {
    try {
      print("Starting file upload process...");
      print("Bucket ID: $bucketId");
      print("File path: ${file.path}");
      print("File name: $fileName");

      // Read file as bytes for web compatibility
      final bytes = await file.readAsBytes();

      final result = await storage.createFile(
        bucketId: bucketId,
        fileId: ID.unique(),
        file: InputFile.fromBytes(
          bytes: bytes,
          filename: fileName,
        ),
      );

      print("File uploaded successfully with ID: ${result.$id}");
      return result.$id;
    } on AppwriteException catch (e) {
      print("Appwrite Error Code: ${e.code}");
      print("Appwrite Error Message: ${e.message}");
      print("Appwrite Error Type: ${e.type}");
      rethrow;
    } catch (e, stackTrace) {
      print("Error in uploadFile: $e");
      print("Stack trace: $stackTrace");
      rethrow;
    }
  }

  // Get file download URL
  static Uri getFileDownloadUrl({
    required String bucketId,
    required String fileId,
  }) {
    return Uri.parse(
      '${client.endPoint}/storage/buckets/$bucketId/files/$fileId/download?project=${client.config['project']}',
    );
  }

  // Get file preview URL (for images)
  static Uri getFilePreviewUrl({
    required String bucketId,
    required String fileId,
  }) {
    return Uri.parse(
      '${client.endPoint}/storage/buckets/$bucketId/files/$fileId/preview?project=${client.config['project']}',
    );
  }

  // Get file view URL
  static Uri getFileViewUrl({
    required String bucketId,
    required String fileId,
  }) {
    return Uri.parse(
      '${client.endPoint}/storage/buckets/$bucketId/files/$fileId/view?project=${client.config['project']}',
    );
  }

  // Delete file
  static Future<void> deleteFile({
    required String bucketId,
    required String fileId,
  }) async {
    try {
      await storage.deleteFile(
        bucketId: bucketId,
        fileId: fileId,
      );
    } catch (e) {
      print("Error deleting file: $e");
      rethrow;
    }
  }
}
