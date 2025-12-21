// =============================================================================
// ForumService Unit Tests
// =============================================================================
// Tests for the ForumService class covering:
// - Permission helper methods (canEditPost, canDelete, canPin)
// - Static method behavior
// - Edge cases for authorization logic
//
// BONUS: Unit Testing with >70% coverage
// Note: API methods (deletePost, deleteReply) require mocking of CookieRequest
// which is tested separately in integration tests.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon_mobile/forum/services/forum_service.dart';

void main() {
  group('ForumService Tests', () {
    // =========================================================================
    // canEditPost Tests
    // =========================================================================

    group('canEditPost', () {
      test('should return true when usernames match', () {
        expect(
          ForumService.canEditPost('testuser', 'testuser'),
          true,
        );
      });

      test('should return false when usernames do not match', () {
        expect(
          ForumService.canEditPost('testuser', 'otheruser'),
          false,
        );
      });

      test('should return false when current username is null', () {
        expect(
          ForumService.canEditPost(null, 'testuser'),
          false,
        );
      });

      test('should return false when author username is null', () {
        expect(
          ForumService.canEditPost('testuser', null),
          false,
        );
      });

      test('should return false when both usernames are null', () {
        expect(
          ForumService.canEditPost(null, null),
          false,
        );
      });

      test('should be case sensitive', () {
        expect(
          ForumService.canEditPost('TestUser', 'testuser'),
          false,
        );
      });

      test('should handle empty strings', () {
        expect(
          ForumService.canEditPost('', ''),
          true, // Empty strings are equal
        );
      });

      test('should handle whitespace differences', () {
        expect(
          ForumService.canEditPost('testuser', 'testuser '),
          false,
        );
      });
    });

    // =========================================================================
    // canDelete Tests
    // =========================================================================

    group('canDelete', () {
      // Admin tests
      test('should return true for ADMIN regardless of authorship', () {
        expect(
          ForumService.canDelete('admin', 'otheruser', 'ADMIN'),
          true,
        );
      });

      test('should return true for ADMIN even when current username is null', () {
        expect(
          ForumService.canDelete(null, 'testuser', 'ADMIN'),
          true,
        );
      });

      test('should return true for ADMIN even when author username is null', () {
        expect(
          ForumService.canDelete('admin', null, 'ADMIN'),
          true,
        );
      });

      test('should return true for ADMIN when both usernames are null', () {
        expect(
          ForumService.canDelete(null, null, 'ADMIN'),
          true,
        );
      });

      // Author tests (non-admin)
      test('should return true for author (matching usernames)', () {
        expect(
          ForumService.canDelete('testuser', 'testuser', 'USER'),
          true,
        );
      });

      test('should return false for non-author non-admin', () {
        expect(
          ForumService.canDelete('testuser', 'otheruser', 'USER'),
          false,
        );
      });

      test('should return false when current username is null and not admin', () {
        expect(
          ForumService.canDelete(null, 'testuser', 'USER'),
          false,
        );
      });

      test('should return false when author username is null and not admin', () {
        expect(
          ForumService.canDelete('testuser', null, 'USER'),
          false,
        );
      });

      // Role variations
      test('should return false for SELLER who is not author', () {
        expect(
          ForumService.canDelete('seller', 'testuser', 'SELLER'),
          false,
        );
      });

      test('should return true for SELLER who is author', () {
        expect(
          ForumService.canDelete('seller', 'seller', 'SELLER'),
          true,
        );
      });

      test('should return false for FACILITY_ADMIN who is not author', () {
        expect(
          ForumService.canDelete('facility', 'testuser', 'FACILITY_ADMIN'),
          false,
        );
      });

      test('should return true for FACILITY_ADMIN who is author', () {
        expect(
          ForumService.canDelete('facility', 'facility', 'FACILITY_ADMIN'),
          true,
        );
      });

      // Null role tests
      test('should return true for author when role is null', () {
        expect(
          ForumService.canDelete('testuser', 'testuser', null),
          true,
        );
      });

      test('should return false for non-author when role is null', () {
        expect(
          ForumService.canDelete('testuser', 'otheruser', null),
          false,
        );
      });

      // Case sensitivity
      test('canDelete should be case sensitive for usernames', () {
        expect(
          ForumService.canDelete('TestUser', 'testuser', 'USER'),
          false,
        );
      });

      test('canDelete should be case sensitive for role (only ADMIN works)', () {
        expect(
          ForumService.canDelete('testuser', 'otheruser', 'admin'),
          false, // lowercase 'admin' should not work
        );
      });

      test('canDelete should be case sensitive for role (Admin variant)', () {
        expect(
          ForumService.canDelete('testuser', 'otheruser', 'Admin'),
          false, // 'Admin' is not equal to 'ADMIN'
        );
      });
    });

    // =========================================================================
    // canPin Tests
    // =========================================================================

    group('canPin', () {
      test('should return true for ADMIN role', () {
        expect(ForumService.canPin('ADMIN'), true);
      });

      test('should return false for USER role', () {
        expect(ForumService.canPin('USER'), false);
      });

      test('should return false for SELLER role', () {
        expect(ForumService.canPin('SELLER'), false);
      });

      test('should return false for FACILITY_ADMIN role', () {
        expect(ForumService.canPin('FACILITY_ADMIN'), false);
      });

      test('should return false for null role', () {
        expect(ForumService.canPin(null), false);
      });

      test('should return false for empty string role', () {
        expect(ForumService.canPin(''), false);
      });

      test('should be case sensitive (lowercase admin)', () {
        expect(ForumService.canPin('admin'), false);
      });

      test('should be case sensitive (mixed case Admin)', () {
        expect(ForumService.canPin('Admin'), false);
      });
    });

    // =========================================================================
    // Integration Scenarios
    // =========================================================================

    group('Integration Scenarios', () {
      test('regular user can only edit and delete their own posts', () {
        const currentUsername = 'testuser';
        const authorUsername = 'testuser';
        const role = 'USER';

        expect(ForumService.canEditPost(currentUsername, authorUsername), true);
        expect(ForumService.canDelete(currentUsername, authorUsername, role), true);
        expect(ForumService.canPin(role), false);
      });

      test('regular user cannot edit or delete others posts', () {
        const currentUsername = 'testuser';
        const authorUsername = 'otheruser';
        const role = 'USER';

        expect(ForumService.canEditPost(currentUsername, authorUsername), false);
        expect(ForumService.canDelete(currentUsername, authorUsername, role), false);
      });

      test('admin can delete any post but cannot edit others posts', () {
        const currentUsername = 'admin';
        const authorUsername = 'testuser';
        const role = 'ADMIN';

        expect(ForumService.canEditPost(currentUsername, authorUsername), false);
        expect(ForumService.canDelete(currentUsername, authorUsername, role), true);
        expect(ForumService.canPin(role), true);
      });

      test('admin can edit and delete their own posts and pin', () {
        const currentUsername = 'admin';
        const authorUsername = 'admin';
        const role = 'ADMIN';

        expect(ForumService.canEditPost(currentUsername, authorUsername), true);
        expect(ForumService.canDelete(currentUsername, authorUsername, role), true);
        expect(ForumService.canPin(role), true);
      });

      test('seller can only manage their own content', () {
        const currentUsername = 'shopowner';
        const myPost = 'shopowner';
        const othersPost = 'customer';
        const role = 'SELLER';

        expect(ForumService.canEditPost(currentUsername, myPost), true);
        expect(ForumService.canDelete(currentUsername, myPost, role), true);
        expect(ForumService.canEditPost(currentUsername, othersPost), false);
        expect(ForumService.canDelete(currentUsername, othersPost, role), false);
        expect(ForumService.canPin(role), false);
      });

      test('unauthenticated user cannot do anything', () {
        const String? currentUsername = null;
        const authorUsername = 'testuser';
        const String? role = null;

        expect(ForumService.canEditPost(currentUsername, authorUsername), false);
        expect(ForumService.canDelete(currentUsername, authorUsername, role), false);
        expect(ForumService.canPin(role), false);
      });
    });
  });
}
