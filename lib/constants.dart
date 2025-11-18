import 'package:flutter/foundation.dart';

const String _androidUrl = 'http://10.0.2.2:8000';
const String _defaultUrl = 'http://127.0.0.1:8000';

String get baseUrl {
	if (kIsWeb) return _defaultUrl;

	switch (defaultTargetPlatform) {
		case TargetPlatform.android:
			return _androidUrl;
		default:
			return _defaultUrl;
	}
}
