import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  /// Get Supabase URL from environment variables
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  
  /// Get Supabase Anon Key from environment variables
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Initialize Supabase
  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'Supabase credentials not found. Please ensure .env file exists with SUPABASE_URL and SUPABASE_ANON_KEY'
      );
    }
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: false,
    );
  }

  /// Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get Storage client for file operations
  static SupabaseStorageClient get storage => client.storage;
}