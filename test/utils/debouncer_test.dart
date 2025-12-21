// =============================================================================
// Debouncer & Throttler Unit Tests
// =============================================================================
// Tests for the Debouncer and Throttler utility classes covering:
// - Basic debounce functionality
// - Cancellation
// - Disposal
// - Multiple rapid calls
// - Throttle functionality
//
// BONUS: Unit Testing with >70% coverage
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon_mobile/utils/debouncer.dart';

void main() {
  group('Debouncer Tests', () {
    late Debouncer debouncer;

    setUp(() {
      debouncer = Debouncer(milliseconds: 100);
    });

    tearDown(() {
      debouncer.dispose();
    });

    // =========================================================================
    // Constructor Tests
    // =========================================================================

    group('Constructor', () {
      test('should create debouncer with specified milliseconds', () {
        final customDebouncer = Debouncer(milliseconds: 500);
        expect(customDebouncer, isNotNull);
        customDebouncer.dispose();
      });

      test('should create debouncer with zero milliseconds', () {
        final zeroDebouncer = Debouncer(milliseconds: 0);
        expect(zeroDebouncer, isNotNull);
        zeroDebouncer.dispose();
      });

      test('should create debouncer with large milliseconds', () {
        final longDebouncer = Debouncer(milliseconds: 10000);
        expect(longDebouncer, isNotNull);
        longDebouncer.dispose();
      });

      test('should create debouncer from Duration', () {
        final durationDebouncer = Debouncer.fromDuration(Duration(milliseconds: 200));
        expect(durationDebouncer, isNotNull);
        expect(durationDebouncer.milliseconds, 200);
        durationDebouncer.dispose();
      });
    });

    // =========================================================================
    // Run Method Tests
    // =========================================================================

    group('Run Method', () {
      test('should execute callback after delay', () async {
        int callCount = 0;
        
        debouncer.run(() {
          callCount++;
        });
        
        // Before delay
        expect(callCount, 0);
        
        // Wait for debounce
        await Future.delayed(Duration(milliseconds: 150));
        
        expect(callCount, 1);
      });

      test('should only execute last callback when called rapidly', () async {
        int value = 0;
        
        debouncer.run(() => value = 1);
        debouncer.run(() => value = 2);
        debouncer.run(() => value = 3);
        
        // Wait for debounce
        await Future.delayed(Duration(milliseconds: 150));
        
        expect(value, 3); // Only last value should be set
      });

      test('should reset timer on each call', () async {
        int callCount = 0;
        
        debouncer.run(() => callCount++);
        await Future.delayed(Duration(milliseconds: 50));
        
        debouncer.run(() => callCount++);
        await Future.delayed(Duration(milliseconds: 50));
        
        debouncer.run(() => callCount++);
        await Future.delayed(Duration(milliseconds: 150));
        
        expect(callCount, 1); // Should only execute once after final debounce
      });
    });

    // =========================================================================
    // RunWithDelay Method Tests
    // =========================================================================

    group('RunWithDelay Method', () {
      test('should execute with custom delay', () async {
        int callCount = 0;
        
        debouncer.runWithDelay(() => callCount++, delayMs: 50);
        
        // Before custom delay
        expect(callCount, 0);
        
        // Wait for custom debounce
        await Future.delayed(Duration(milliseconds: 80));
        
        expect(callCount, 1);
      });

      test('custom delay should override default', () async {
        int value = 0;
        
        // Start with default delay
        debouncer.run(() => value = 1);
        
        // Override with shorter custom delay
        debouncer.runWithDelay(() => value = 2, delayMs: 30);
        
        await Future.delayed(Duration(milliseconds: 50));
        
        expect(value, 2);
      });
    });

    // =========================================================================
    // Cancel Tests
    // =========================================================================

    group('Cancel Method', () {
      test('should cancel pending callback', () async {
        int callCount = 0;
        
        debouncer.run(() => callCount++);
        debouncer.cancel();
        
        await Future.delayed(Duration(milliseconds: 150));
        
        expect(callCount, 0);
      });

      test('cancel should work when no callback is pending', () {
        // Should not throw
        expect(() => debouncer.cancel(), returnsNormally);
      });

      test('cancel should work multiple times', () {
        expect(() {
          debouncer.cancel();
          debouncer.cancel();
          debouncer.cancel();
        }, returnsNormally);
      });

      test('should be able to run new callback after cancel', () async {
        int value = 0;
        
        debouncer.run(() => value = 1);
        debouncer.cancel();
        debouncer.run(() => value = 2);
        
        await Future.delayed(Duration(milliseconds: 150));
        
        expect(value, 2);
      });
    });

    // =========================================================================
    // IsPending Tests
    // =========================================================================

    group('IsPending Property', () {
      test('should be false initially', () {
        final freshDebouncer = Debouncer(milliseconds: 100);
        expect(freshDebouncer.isPending, false);
        freshDebouncer.dispose();
      });

      test('should be true after run is called', () {
        debouncer.run(() {});
        expect(debouncer.isPending, true);
      });

      test('should be false after callback executes', () async {
        debouncer.run(() {});
        
        await Future.delayed(Duration(milliseconds: 150));
        
        expect(debouncer.isPending, false);
      });

      test('should be false after cancel', () {
        debouncer.run(() {});
        debouncer.cancel();
        expect(debouncer.isPending, false);
      });
    });

    // =========================================================================
    // Dispose Tests
    // =========================================================================

    group('Dispose Method', () {
      test('should cancel pending callbacks', () async {
        int callCount = 0;
        
        final disposableDebouncer = Debouncer(milliseconds: 100);
        disposableDebouncer.run(() => callCount++);
        disposableDebouncer.dispose();
        
        await Future.delayed(Duration(milliseconds: 150));
        
        expect(callCount, 0);
      });

      test('dispose should work when no callback is pending', () {
        final freshDebouncer = Debouncer(milliseconds: 100);
        expect(() => freshDebouncer.dispose(), returnsNormally);
      });

      test('run should not work after dispose', () async {
        int callCount = 0;
        
        final disposableDebouncer = Debouncer(milliseconds: 100);
        disposableDebouncer.dispose();
        disposableDebouncer.run(() => callCount++);
        
        await Future.delayed(Duration(milliseconds: 150));
        
        expect(callCount, 0);
      });
    });

    // =========================================================================
    // Edge Cases
    // =========================================================================

    group('Edge Cases', () {
      test('should handle empty callback', () async {
        debouncer.run(() {});
        
        await Future.delayed(Duration(milliseconds: 150));
        
        // Should complete without error
        expect(true, true);
      });
    });
  });

  // ===========================================================================
  // Throttler Tests
  // ===========================================================================

  group('Throttler Tests', () {
    late Throttler throttler;

    setUp(() {
      throttler = Throttler(milliseconds: 100);
    });

    tearDown(() {
      throttler.dispose();
    });

    // =========================================================================
    // Constructor Tests
    // =========================================================================

    group('Constructor', () {
      test('should create throttler with specified milliseconds', () {
        final customThrottler = Throttler(milliseconds: 500);
        expect(customThrottler, isNotNull);
        customThrottler.dispose();
      });
    });

    // =========================================================================
    // Run Method Tests
    // =========================================================================

    group('Run Method', () {
      test('should execute first callback immediately', () {
        int callCount = 0;
        
        throttler.run(() => callCount++);
        
        expect(callCount, 1);
      });

      test('should track different values correctly', () async {
        int value = 0;
        
        throttler.run(() => value = 1); // Executes immediately
        
        expect(value, 1);
        
        await Future.delayed(Duration(milliseconds: 150));
        
        throttler.run(() => value = 4); // Should execute after wait
        
        expect(value, 4);
      });
    });

    // =========================================================================
    // Cancel Tests
    // =========================================================================

    group('Cancel Method', () {
      test('should cancel pending trailing action', () async {
        int callCount = 0;
        
        throttler.run(() => callCount++); // First call executes
        throttler.run(() => callCount++); // Schedules trailing
        throttler.cancel();               // Cancel trailing
        
        await Future.delayed(Duration(milliseconds: 150));
        
        expect(callCount, 1); // Only first call executed
      });

      test('cancel should work when no callback is pending', () {
        expect(() => throttler.cancel(), returnsNormally);
      });
    });

    // =========================================================================
    // Dispose Tests
    // =========================================================================

    group('Dispose Method', () {
      test('should work without error', () {
        expect(() => throttler.dispose(), returnsNormally);
      });

      test('should work after run', () {
        throttler.run(() {});
        expect(() => throttler.dispose(), returnsNormally);
      });

      test('run should not work after dispose', () {
        int callCount = 0;
        
        final disposableThrottler = Throttler(milliseconds: 100);
        disposableThrottler.dispose();
        disposableThrottler.run(() => callCount++);
        
        expect(callCount, 0);
      });
    });

    // =========================================================================
    // Edge Cases
    // =========================================================================

    group('Edge Cases', () {
      test('should handle empty callback', () {
        expect(() => throttler.run(() {}), returnsNormally);
      });
    });
  });
}
