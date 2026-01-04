import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Service for handling file uploads to Supabase Storage
class FileUploadService {
  static const String bucketName = 'print-documents';
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedMimeTypes = ['application/pdf'];
  static const List<String> allowedExtensions = ['pdf'];

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Authenticate with Supabase using Firebase user info
  Future<void> _authenticateWithSupabase() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw FileUploadException('User not authenticated with Firebase');
    }

    try {
      // Sign in anonymously to Supabase or use existing session
      final supabaseUser = SupabaseConfig.client.auth.currentUser;
      if (supabaseUser == null) {
        await SupabaseConfig.client.auth.signInAnonymously();
        print('Signed in to Supabase anonymously');
      } else {
        print('Using existing Supabase session');
      }
    } catch (e) {
      print('Supabase auth failed: $e');
      // Continue anyway - the bucket should be public
    }
  }

  /// Pick a PDF file from device
  Future<PlatformFile?> pickPDFFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        
        // Validate file size
        if (file.size > maxFileSizeBytes) {
          throw FileUploadException(
            'File size exceeds 10MB limit. Selected file: ${(file.size / (1024 * 1024)).toStringAsFixed(1)}MB'
          );
        }

        // Validate file type
        String? mimeType;
        if (file.path != null) {
          mimeType = lookupMimeType(file.path!);
        }
        
        if (mimeType == null || !allowedMimeTypes.contains(mimeType)) {
          throw FileUploadException('Only PDF files are allowed');
        }

        return file;
      }
      return null;
    } catch (e) {
      if (e is FileUploadException) rethrow;
      throw FileUploadException('Failed to pick file: $e');
    }
  }

  /// Upload file to Supabase Storage
  Future<String> uploadFile(PlatformFile file, String jobId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw FileUploadException('User not authenticated');
      }

      // Authenticate with Supabase
      await _authenticateWithSupabase();

      // Generate file path: /print-documents/{userId}/{jobId}/{filename}
      final fileName = _sanitizeFileName(file.name);
      final filePath = '$userId/$jobId/$fileName';

      print('Uploading file to: $filePath');

      // Get file bytes
      Uint8List? fileBytes;
      if (file.bytes != null) {
        fileBytes = file.bytes!;
      } else if (file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      } else {
        throw FileUploadException('Unable to read file data');
      }

      // Upload to Supabase Storage
      final response = await SupabaseConfig.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: 'application/pdf',
              upsert: true, // Allow overwriting
            ),
          );

      print('Upload response: $response');

      // Get public URL
      final publicUrl = SupabaseConfig.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      print('File uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('File upload failed: $e');
      if (e.toString().contains('row-level security') || 
          e.toString().contains('RLS') ||
          e.toString().contains('Unauthorized')) {
        throw FileUploadException(
          'Storage access denied. Please check Supabase bucket policies and ensure the bucket is public or RLS is properly configured.'
        );
      }
      throw FileUploadException('Upload failed: $e');
    }
  }

  /// Delete file from Supabase Storage
  Future<bool> deleteFile(String jobId, String fileName) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('User not authenticated - cannot delete file');
        return false;
      }

      // Authenticate with Supabase
      await _authenticateWithSupabase();

      final filePath = '$userId/$jobId/${_sanitizeFileName(fileName)}';
      
      await SupabaseConfig.storage
          .from(bucketName)
          .remove([filePath]);

      print('File deleted successfully: $filePath');
      return true;
    } catch (e) {
      print('File deletion failed: $e');
      return false;
    }
  }

  /// Get file download URL (same as public URL for now)
  String getFileUrl(String userId, String jobId, String fileName) {
    final filePath = '$userId/$jobId/${_sanitizeFileName(fileName)}';
    return SupabaseConfig.storage
        .from(bucketName)
        .getPublicUrl(filePath);
  }

  /// Sanitize filename to be storage-safe
  String _sanitizeFileName(String fileName) {
    // Remove or replace problematic characters
    return fileName
        .replaceAll(RegExp(r'[^\w\-_\.]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  /// Check if file exists in storage
  Future<bool> fileExists(String jobId, String fileName) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Authenticate with Supabase
      await _authenticateWithSupabase();

      final filePath = '$userId/$jobId/${_sanitizeFileName(fileName)}';
      
      final files = await SupabaseConfig.storage
          .from(bucketName)
          .list(path: '$userId/$jobId');
          
      return files.any((file) => file.name == _sanitizeFileName(fileName));
    } catch (e) {
      print('Error checking file existence: $e');
      return false;
    }
  }

  /// Get file size in a human-readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Custom exception for file upload errors
class FileUploadException implements Exception {
  final String message;
  const FileUploadException(this.message);
  
  @override
  String toString() => message;
}