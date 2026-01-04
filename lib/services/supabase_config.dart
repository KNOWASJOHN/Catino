import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  // TODO: Replace with your actual Supabase project URL and anon key
  static const String supabaseUrl = 'https://wbvrndjwnhrjbpidtkjy.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_F00gG8GMVWhNOrNH2VI4Qw_JFHS5t8P';

  /// Initialize Supabase
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: true, // Set to false in production
      );
      print('Supabase initialized successfully');
    } catch (e) {
      print('Failed to initialize Supabase: $e');
      rethrow;
    }
  }

  /// Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get Storage client for file operations
  static SupabaseStorageClient get storage => client.storage;
}