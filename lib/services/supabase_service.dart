import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import '../utils/environment.dart';

class SupabaseService {

  // Initialize Supabase
  static Future<void> initialize() async {
    try {
      print('SupabaseService: Initializing Supabase...');
      print('SupabaseService: URL: ${Environment.supabaseUrl}');
      print('SupabaseService: Anon Key: ${Environment.supabaseAnonKey.substring(0, 20)}...');
      
      await Supabase.initialize(
        url: Environment.supabaseUrl,
        anonKey: Environment.supabaseAnonKey,
      );
      
      print('SupabaseService: Initialization successful');
      
      // Test connection
      await testConnection();
    } catch (e) {
      print('SupabaseService: Initialization failed: $e');
      rethrow;
    }
  }

  // Test Supabase connection
  static Future<void> testConnection() async {
    try {
      print('SupabaseService: Testing connection...');
      
      // Try to list buckets to test connection
      final buckets = await Supabase.instance.client.storage.listBuckets();
      print('SupabaseService: Available buckets: ${buckets.map((b) => b.name).toList()}');
      
      // Check if our bucket exists
      final issueImagesBucket = buckets.where((b) => b.name == 'issue_images').isNotEmpty;
      if (!issueImagesBucket) {
        print('SupabaseService: WARNING - issue_images bucket not found!');
      } else {
        print('SupabaseService: issue_images bucket found');
      }
      
    } catch (e) {
      print('SupabaseService: Connection test failed: $e');
      rethrow;
    }
  }

  // Upload image to Supabase Storage
  static Future<String?> uploadImage(File file, String fileName) async {
    try {
      print('SupabaseService: Starting image upload for file: $fileName');
      print('SupabaseService: File size: ${await file.length()} bytes');
      
      // Check if Supabase is initialized
      if (Supabase.instance.client == null) {
        throw Exception('Supabase client is not initialized');
      }
      
      // Upload the file
      final response = await Supabase.instance.client.storage
          .from('issue_images')
          .upload(fileName, file);
      
      print('SupabaseService: Upload response: $response');

      // Get public URL
      final String publicUrl = Supabase.instance.client.storage
          .from('issue_images')
          .getPublicUrl(fileName);
      
      print('SupabaseService: Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('SupabaseService: Upload error: $e');
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
