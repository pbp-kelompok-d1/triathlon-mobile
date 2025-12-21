// =============================================================================
// Application Constants
// =============================================================================
// This file provides backward-compatible access to configuration values.
// 
// BONUS: Now integrates with EnvConfig for environment-based configuration.
// The old hardcoded values are kept as fallbacks for compatibility.
// =============================================================================

import 'package:flutter/foundation.dart';

// Import environment configuration for dynamic values
import 'config/env_config.dart';

// Legacy fallback URLs (used if env config not loaded)
const String _androidUrl = 'http://10.0.2.2:8000';
const String _defaultUrl = 'http://127.0.0.1:8000';
const String _pwsUrl = 'https://muhammad-kaila-triathlon.pbp.cs.ui.ac.id';

// Flip this at build time with: flutter run --dart-define=USE_PWS=false (to use local)
const bool _usePwsUrl = bool.fromEnvironment('USE_PWS', defaultValue: true);

/// Get the base URL for API calls
/// BONUS: Now uses EnvConfig for dynamic configuration
String get baseUrl {
  // Try to get from environment config first
  try {
    return env.apiBaseUrl;
  } catch (e) {
    // Fallback to legacy behavior if env not loaded
    return _legacyBaseUrl;
  }
}

/// Legacy base URL resolution (fallback)
String get _legacyBaseUrl {
	if (_usePwsUrl) {
		return _pwsUrl;
	}

	// Web builds can always loop back to localhost directly.
	if (kIsWeb) return _defaultUrl;

	switch (defaultTargetPlatform) {
		case TargetPlatform.android:
			// Android emulators need the 10.0.2.2 alias to reach the host machine.
			return _androidUrl;
		default:
			// iOS/macOS/Windows/Linux desktops can hit localhost as-is.
			return _defaultUrl;
	}
}

String buildProxyImageUrl(String sourceUrl) {
	return '$baseUrl/shop/api/proxy-image/?url=${Uri.encodeComponent(sourceUrl)}';
}

