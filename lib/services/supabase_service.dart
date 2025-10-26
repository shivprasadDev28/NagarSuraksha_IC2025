import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import '../utils/environment.dart';

class SupabaseService {

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
    );
  }

  // Upload image to Supabase Storage
  static Future<String?> uploadImage(File file, String fileName) async {
    try {
      await Supabase.instance.client.storage
          .from('issue_images')
          .upload(fileName, file);

      // Get public URL
      final String publicUrl = Supabase.instance.client.storage
          .from('issue_images')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload image from bytes
  static Future<String?> uploadImageFromBytes(Uint8List imageBytes, String fileName) async {
    try {
      await Supabase.instance.client.storage
          .from('issue_images')
          .uploadBinary(fileName, imageBytes);

      // Get public URL
      final String publicUrl = Supabase.instance.client.storage
          .from('issue_images')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete image from Supabase Storage
  static Future<void> deleteImage(String fileName) async {
    try {
      await Supabase.instance.client.storage
          .from('issue_images')
          .remove([fileName]);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // Get signed URL for private access (if needed)
  static Future<String?> getSignedUrl(String fileName) async {
    try {
      final String signedUrl = await Supabase.instance.client.storage
          .from('issue_images')
          .createSignedUrl(fileName, 60 * 60); // 1 hour expiry

      return signedUrl;
    } catch (e) {
      throw Exception('Failed to get signed URL: $e');
    }
  }

  // List all images in bucket
  static Future<List<String>> listImages() async {
    try {
      final List<FileObject> files = await Supabase.instance.client.storage
          .from('issue_images')
          .list();

      return files.map((file) => file.name).toList();
    } catch (e) {
      throw Exception('Failed to list images: $e');
    }
  }
}
