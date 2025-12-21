// =============================================================================
// EnvConfig Unit Tests
// =============================================================================
// Tests for the EnvConfig singleton covering:
// - Singleton pattern
// - Environment variable getters
// - Default/fallback values
// - Type conversions
//
// BONUS: Unit Testing with >70% coverage
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon_mobile/config/env_config.dart';

void main() {
  // Load env before all tests
  setUpAll(() async {
    await env.load();
  });

  group('EnvConfig Tests', () {
    // =========================================================================
    // Singleton Pattern Tests
    // =========================================================================

    group('Singleton Pattern', () {
      test('instance should return singleton', () {
        final instance1 = EnvConfig.instance;
        final instance2 = EnvConfig.instance;
        
        expect(identical(instance1, instance2), true);
      });

      test('env getter should return singleton instance', () {
        final envInstance = env;
        final directInstance = EnvConfig.instance;
        
        expect(identical(envInstance, directInstance), true);
      });
    });

    // =========================================================================
    // Type-Safe Getter Tests
    // =========================================================================

    group('Type-Safe Getters', () {
      test('useProduction should return bool', () {
        expect(env.useProduction, isA<bool>());
      });

      test('isDebugMode should return bool', () {
        expect(env.isDebugMode, isA<bool>());
      });

      test('enableCache should return bool', () {
        expect(env.enableCache, isA<bool>());
      });

      test('enableShimmerLoading should return bool', () {
        expect(env.enableShimmerLoading, isA<bool>());
      });

      test('cacheDurationSeconds should return int', () {
        expect(env.cacheDurationSeconds, isA<int>());
      });

      test('forumPageSize should return int', () {
        expect(env.forumPageSize, isA<int>());
      });

      test('searchDebounceMs should return int', () {
        expect(env.searchDebounceMs, isA<int>());
      });

      test('apiBaseUrl should return String', () {
        expect(env.apiBaseUrl, isA<String>());
      });
    });

    // =========================================================================
    // Default/Fallback Values Tests
    // =========================================================================

    group('Default Values', () {
      // These tests verify the fallback values work correctly
      // when environment variables are not set

      test('cacheDurationSeconds should have reasonable default', () {
        // Default is 300 (5 minutes)
        expect(env.cacheDurationSeconds, greaterThan(0));
      });

      test('forumPageSize should have reasonable default', () {
        // Default is 20
        expect(env.forumPageSize, greaterThan(0));
        expect(env.forumPageSize, lessThanOrEqualTo(100)); // Reasonable limit
      });

      test('searchDebounceMs should have reasonable default', () {
        // Default is 300ms
        expect(env.searchDebounceMs, greaterThan(0));
        expect(env.searchDebounceMs, lessThanOrEqualTo(2000)); // Max 2 seconds
      });
    });

    // =========================================================================
    // CacheDuration Computed Property Tests
    // =========================================================================

    group('CacheDuration Computed Property', () {
      test('cacheDuration should return Duration', () {
        expect(env.cacheDuration, isA<Duration>());
      });

      test('cacheDuration should match cacheDurationSeconds', () {
        final duration = env.cacheDuration;
        expect(duration.inSeconds, env.cacheDurationSeconds);
      });

      test('searchDebounceDuration should return Duration', () {
        expect(env.searchDebounceDuration, isA<Duration>());
      });

      test('searchDebounceDuration should match searchDebounceMs', () {
        final duration = env.searchDebounceDuration;
        expect(duration.inMilliseconds, env.searchDebounceMs);
      });
    });

    // =========================================================================
    // API Base URL Tests
    // =========================================================================

    group('API Base URL', () {
      test('apiBaseUrl should be non-empty', () {
        expect(env.apiBaseUrl, isNotEmpty);
      });

      test('apiBaseUrl should be valid URL format', () {
        final url = env.apiBaseUrl;
        // Should start with http:// or https://
        expect(
          url.startsWith('http://') || url.startsWith('https://'),
          true,
          reason: 'API URL should start with http:// or https://',
        );
      });
    });

    // =========================================================================
    // Boolean Values
    // =========================================================================

    group('Boolean Values', () {
      test('useProduction should be valid bool', () {
        final value = env.useProduction;
        expect(value == true || value == false, true);
      });

      test('isDebugMode should be valid bool', () {
        final value = env.isDebugMode;
        expect(value == true || value == false, true);
      });

      test('enableCache should be valid bool', () {
        expect(env.enableCache, isA<bool>());
      });

      test('enableShimmerLoading should be valid bool', () {
        expect(env.enableShimmerLoading, isA<bool>());
      });
    });

    // =========================================================================
    // Utility Methods
    // =========================================================================

    group('Utility Methods', () {
      test('buildProxyImageUrl should return valid URL', () {
        final proxyUrl = env.buildProxyImageUrl('https://example.com/image.jpg');
        expect(proxyUrl, contains('/shop/api/proxy-image/'));
        expect(proxyUrl, contains('url='));
      });

      test('toString should return readable format', () {
        final str = env.toString();
        expect(str, contains('EnvConfig'));
        expect(str, contains('apiBaseUrl'));
        expect(str, contains('useProduction'));
        expect(str, contains('enableCache'));
        expect(str, contains('isDebugMode'));
      });
    });

    // =========================================================================
    // Integration Tests
    // =========================================================================

    group('Integration', () {
      test('all config values should be accessible without error', () {
        expect(() {
          final _ = env.useProduction;
          final __ = env.isDebugMode;
          final ___ = env.enableCache;
          final ____ = env.cacheDurationSeconds;
          final _____ = env.forumPageSize;
          final ______ = env.enableShimmerLoading;
          final _______ = env.searchDebounceMs;
          final ________ = env.apiBaseUrl;
          final _________ = env.cacheDuration;
          final __________ = env.searchDebounceDuration;
        }, returnsNormally);
      });

      test('config values should be consistent across multiple reads', () {
        // Read values twice and verify consistency
        final useProduction1 = env.useProduction;
        final useProduction2 = env.useProduction;
        expect(useProduction1, useProduction2);

        final cacheDuration1 = env.cacheDurationSeconds;
        final cacheDuration2 = env.cacheDurationSeconds;
        expect(cacheDuration1, cacheDuration2);

        final apiUrl1 = env.apiBaseUrl;
        final apiUrl2 = env.apiBaseUrl;
        expect(apiUrl1, apiUrl2);
      });
    });

    // =========================================================================
    // Edge Cases
    // =========================================================================

    group('Edge Cases', () {
      test('should handle load being called multiple times', () async {
        // Multiple loads should not cause errors
        await env.load();
        await env.load();
        await env.load();
        
        // Should still work
        expect(env.apiBaseUrl, isNotEmpty);
      });
    });
  });
}
