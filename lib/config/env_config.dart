// =============================================================================
// Environment Configuration Service
// =============================================================================
// This service provides centralized access to environment variables loaded
// from .env file using flutter_dotenv package.
//
// BONUS IMPLEMENTATION: API Key & Environment Variable Management
// This demonstrates professional-grade configuration management including:
// - Type-safe access to environment variables
// - Default values for missing configurations
// - Feature flags for enabling/disabling features
// - Debug mode support
// - Caching configuration
//
// BENEFITS:
// 1. Security: Sensitive data not hardcoded in source code
// 2. Flexibility: Easy switching between dev/prod environments
// 3. Maintainability: Centralized configuration management
// 4. Type Safety: Proper parsing of different data types
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Singleton service for accessing environment configuration
class EnvConfig {
  // Private constructor for singleton pattern
  EnvConfig._();
  
  /// Singleton instance
  static final EnvConfig instance = EnvConfig._();
  
  /// Whether environment has been loaded
  bool _isLoaded = false;
  
  // ===========================================================================
  // Initialization
  // ===========================================================================
  
  /// Load environment variables from .env file
  /// Call this in main() before runApp()
  Future<void> load() async {
    if (_isLoaded) return;
    
    try {
      await dotenv.load(fileName: '.env');
      _isLoaded = true;
      if (isDebugMode) {
        debugPrint('✅ Environment loaded successfully');
        debugPrint('   API Base URL: $apiBaseUrl');
        debugPrint('   Production Mode: $useProduction');
        debugPrint('   Cache Enabled: $enableCache');
      }
    } catch (e) {
      // Fallback to defaults if .env file doesn't exist
      debugPrint('⚠️ Could not load .env file, using defaults: $e');
      _isLoaded = true;
    }
  }
  
  // ===========================================================================
  // API Configuration Getters
  // ===========================================================================
  
  /// Base URL for the Django backend API
  /// Supports different URLs for Android emulator, iOS simulator, and production
  String get apiBaseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Fallback based on platform
    if (useProduction) {
      return 'https://muhammad-kaila-triathlon.pbp.cs.ui.ac.id';
    }
    
    // Development fallback
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      default:
        return 'http://127.0.0.1:8000';
    }
  }
  
  /// Whether to use production API
  bool get useProduction {
    return _getBool('USE_PRODUCTION', defaultValue: true);
  }
  
  // ===========================================================================
  // Feature Flags
  // ===========================================================================
  
  /// Whether debug mode is enabled
  bool get isDebugMode {
    return _getBool('DEBUG_MODE', defaultValue: kDebugMode);
  }
  
  /// Whether caching is enabled for forum posts
  bool get enableCache {
    return _getBool('ENABLE_CACHE', defaultValue: true);
  }
  
  /// Cache duration in seconds
  int get cacheDurationSeconds {
    return _getInt('CACHE_DURATION_SECONDS', defaultValue: 300);
  }
  
  /// Cache duration as Duration object
  Duration get cacheDuration {
    return Duration(seconds: cacheDurationSeconds);
  }
  
  // ===========================================================================
  // Forum Module Configuration
  // ===========================================================================
  
  /// Maximum number of posts to load per page
  int get forumPageSize {
    return _getInt('FORUM_PAGE_SIZE', defaultValue: 20);
  }
  
  /// Whether shimmer loading effect is enabled
  bool get enableShimmerLoading {
    return _getBool('ENABLE_SHIMMER_LOADING', defaultValue: true);
  }
  
  /// Debounce delay for search input in milliseconds
  int get searchDebounceMs {
    return _getInt('SEARCH_DEBOUNCE_MS', defaultValue: 300);
  }
  
  /// Search debounce as Duration object
  Duration get searchDebounceDuration {
    return Duration(milliseconds: searchDebounceMs);
  }
  
  // ===========================================================================
  // Helper Methods for Type-Safe Parsing
  // ===========================================================================
  
  /// Get a boolean value from environment
  bool _getBool(String key, {required bool defaultValue}) {
    final value = dotenv.env[key]?.toLowerCase();
    if (value == null) return defaultValue;
    return value == 'true' || value == '1' || value == 'yes';
  }
  
  /// Get an integer value from environment
  int _getInt(String key, {required int defaultValue}) {
    final value = dotenv.env[key];
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }
  
  /// Get a string value from environment
  String _getString(String key, {required String defaultValue}) {
    return dotenv.env[key] ?? defaultValue;
  }
  
  // ===========================================================================
  // Utility Methods
  // ===========================================================================
  
  /// Build proxy image URL for loading external images through backend
  String buildProxyImageUrl(String sourceUrl) {
    return '$apiBaseUrl/shop/api/proxy-image/?url=${Uri.encodeComponent(sourceUrl)}';
  }
  
  /// Get all loaded environment variables (for debugging)
  Map<String, String> get allVariables {
    if (!isDebugMode) return {};
    return Map.from(dotenv.env);
  }
  
  @override
  String toString() {
    return 'EnvConfig('
        'apiBaseUrl: $apiBaseUrl, '
        'useProduction: $useProduction, '
        'enableCache: $enableCache, '
        'isDebugMode: $isDebugMode'
        ')';
  }
}

// =============================================================================
// Convenience Getter
// =============================================================================
// This allows quick access to env config throughout the app:
//   import 'package:triathlon_mobile/config/env_config.dart';
//   final url = env.apiBaseUrl;
// =============================================================================

/// Global accessor for environment configuration
EnvConfig get env => EnvConfig.instance;
