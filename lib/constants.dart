import 'package:flutter/foundation.dart';

// Separate base URLs per platform so Flutter can hit the Django server reliably in dev.
const String _androidUrl = 'http://10.0.2.2:8000';
const String _defaultUrl = 'http://127.0.0.1:8000';

String get baseUrl {
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
