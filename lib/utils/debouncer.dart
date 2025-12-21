// =============================================================================
// Debouncer Utility
// =============================================================================
// A utility class for debouncing function calls, commonly used for:
// - Search input fields (prevent API calls on every keystroke)
// - Scroll event handlers
// - Window resize handlers
// - Any high-frequency event that needs rate limiting
//
// BONUS IMPLEMENTATION: Performance Optimization
// This debouncer prevents excessive API calls during rapid user input,
// improving app responsiveness and reducing server load.
//
// USAGE:
//   final debouncer = Debouncer(milliseconds: 300);
//   textField.onChanged = (value) {
//     debouncer.run(() => performSearch(value));
//   };
//   // Don't forget to dispose: debouncer.dispose();
// =============================================================================

import 'dart:async';

/// Debouncer class for rate-limiting function calls
class Debouncer {
  /// Delay duration in milliseconds
  final int milliseconds;
  
  /// Internal timer
  Timer? _timer;
  
  /// Whether the debouncer has been disposed
  bool _isDisposed = false;
  
  /// Create a debouncer with specified delay
  Debouncer({required this.milliseconds});
  
  /// Create a debouncer from a Duration
  Debouncer.fromDuration(Duration duration) : milliseconds = duration.inMilliseconds;
  
  /// Run the action after the debounce delay
  /// If called again before the delay expires, the timer resets
  void run(void Function() action) {
    if (_isDisposed) return;
    
    // Cancel existing timer
    _timer?.cancel();
    
    // Start new timer
    _timer = Timer(Duration(milliseconds: milliseconds), () {
      if (!_isDisposed) {
        action();
      }
    });
  }
  
  /// Run the action with a custom delay (one-time override)
  void runWithDelay(void Function() action, {required int delayMs}) {
    if (_isDisposed) return;
    
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (!_isDisposed) {
        action();
      }
    });
  }
  
  /// Cancel any pending action
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
  
  /// Dispose the debouncer and cancel any pending action
  void dispose() {
    _isDisposed = true;
    cancel();
  }
  
  /// Whether a debounced action is pending
  bool get isPending => _timer?.isActive ?? false;
}

// =============================================================================
// Throttler Utility (Bonus)
// =============================================================================
// Unlike debouncer (which waits for silence), throttler ensures an action
// is called at most once per time period.
//
// Use cases:
// - Scroll position logging
// - Analytics events
// - Rate-limited API calls
// =============================================================================

/// Throttler class for rate-limiting to max once per time period
class Throttler {
  /// Minimum time between calls in milliseconds
  final int milliseconds;
  
  /// Timestamp of last execution
  DateTime? _lastExecution;
  
  /// Pending action timer
  Timer? _timer;
  
  /// Whether the throttler has been disposed
  bool _isDisposed = false;
  
  /// Create a throttler with specified minimum interval
  Throttler({required this.milliseconds});
  
  /// Run the action, throttled to the configured interval
  void run(void Function() action) {
    if (_isDisposed) return;
    
    final now = DateTime.now();
    
    if (_lastExecution == null ||
        now.difference(_lastExecution!).inMilliseconds >= milliseconds) {
      // Execute immediately
      _lastExecution = now;
      action();
    } else {
      // Schedule for later (trailing edge)
      _timer?.cancel();
      final remaining = milliseconds - now.difference(_lastExecution!).inMilliseconds;
      _timer = Timer(Duration(milliseconds: remaining), () {
        if (!_isDisposed) {
          _lastExecution = DateTime.now();
          action();
        }
      });
    }
  }
  
  /// Cancel any pending action
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
  
  /// Dispose the throttler
  void dispose() {
    _isDisposed = true;
    cancel();
  }
}
