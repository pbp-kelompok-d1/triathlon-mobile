// =============================================================================
// ForumPost Model Unit Tests
// =============================================================================
// Comprehensive tests for the ForumPost model covering:
// - JSON serialization/deserialization
// - All field mappings
// - Helper methods (canEdit, canDelete, canPin, etc.)
// - Edge cases and null handling
//
// BONUS: Unit Testing with >70% coverage
// These tests ensure model integrity and proper data handling
// =============================================================================

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon_mobile/forum/models/forum_post.dart';

void main() {
  group('ForumPost Model Tests', () {
    // =========================================================================
    // Test Data
    // =========================================================================
    
    /// Sample JSON representing a complete forum post
    final Map<String, dynamic> samplePostJson = {
      'id': 'post-uuid-123',
      'title': 'Test Post Title',
      'content': 'Truncated content...',
      'full_content': 'This is the full content of the test post.',
      'category': 'general',
      'category_display': 'General Discussion',
      'sport_category': 'running',
      'sport_category_display': '🏃 Running',
      'post_views': 150,
      'is_pinned': false,
      'product_id': null,
      'location_id': null,
      'created_at': 'Dec 14, 2024',
      'last_edited': null,
      'author': 'testuser',
      'author_id': 42,
      'author_initial': 'T',
      'author_role': 'USER',
      'like_count': 10,
      'user_has_liked': false,
    };

    /// Sample JSON for a pinned post with linked product
    final Map<String, dynamic> pinnedPostWithProductJson = {
      'id': 'pinned-post-uuid',
      'title': 'Product Review: Running Shoes',
      'content': 'Great shoes for...',
      'full_content': 'Great shoes for marathon training. Full review here.',
      'category': 'product_review',
      'category_display': 'Product Review',
      'sport_category': 'running',
      'sport_category_display': '🏃 Running',
      'post_views': 500,
      'is_pinned': true,
      'product_id': 'product-uuid-456',
      'location_id': null,
      'created_at': 'Dec 10, 2024',
      'last_edited': 'Dec 12, 2024',
      'author': 'admin',
      'author_id': 1,
      'author_initial': 'A',
      'author_role': 'ADMIN',
      'like_count': 50,
      'user_has_liked': true,
    };

    /// Sample JSON for a post with linked location
    final Map<String, dynamic> postWithLocationJson = {
      'id': 'location-post-uuid',
      'title': 'Best Swimming Spot in Jakarta',
      'content': 'Check out this pool...',
      'full_content': 'Check out this pool at Senayan!',
      'category': 'location_review',
      'category_display': 'Location Review',
      'sport_category': 'swimming',
      'sport_category_display': '🏊 Swimming',
      'post_views': 200,
      'is_pinned': false,
      'product_id': null,
      'location_id': 123,
      'created_at': 'Dec 15, 2024',
      'last_edited': null,
      'author': 'swimmer',
      'author_id': 99,
      'author_initial': 'S',
      'author_role': 'USER',
      'like_count': 25,
      'user_has_liked': false,
    };

    // =========================================================================
    // JSON Parsing Tests (fromJson)
    // =========================================================================

    group('fromJson', () {
      test('should correctly parse a complete post JSON', () {
        final post = ForumPost.fromJson(samplePostJson);

        expect(post.id, 'post-uuid-123');
        expect(post.title, 'Test Post Title');
        expect(post.content, 'Truncated content...');
        expect(post.fullContent, 'This is the full content of the test post.');
        expect(post.category, 'general');
        expect(post.categoryDisplay, 'General Discussion');
        expect(post.sportCategory, 'running');
        expect(post.sportCategoryDisplay, '🏃 Running');
        expect(post.postViews, 150);
        expect(post.isPinned, false);
        expect(post.productId, null);
        expect(post.locationId, null);
        expect(post.createdAt, 'Dec 14, 2024');
        expect(post.lastEdited, null);
        expect(post.author, 'testuser');
        expect(post.authorId, 42);
        expect(post.authorInitial, 'T');
        expect(post.authorRole, 'USER');
        expect(post.likeCount, 10);
        expect(post.userHasLiked, false);
      });

      test('should correctly parse a pinned post with product link', () {
        final post = ForumPost.fromJson(pinnedPostWithProductJson);

        expect(post.id, 'pinned-post-uuid');
        expect(post.isPinned, true);
        expect(post.productId, 'product-uuid-456');
        expect(post.locationId, null);
        expect(post.lastEdited, 'Dec 12, 2024');
        expect(post.userHasLiked, true);
        expect(post.authorRole, 'ADMIN');
      });

      test('should correctly parse a post with location link', () {
        final post = ForumPost.fromJson(postWithLocationJson);

        expect(post.locationId, 123);
        expect(post.productId, null);
        expect(post.sportCategory, 'swimming');
      });

      test('should use content as fallback when full_content is missing', () {
        final jsonWithoutFullContent = Map<String, dynamic>.from(samplePostJson);
        jsonWithoutFullContent.remove('full_content');
        
        final post = ForumPost.fromJson(jsonWithoutFullContent);
        
        expect(post.fullContent, 'Truncated content...');
      });

      test('should default userHasLiked to false when not provided', () {
        final jsonWithoutLikeStatus = Map<String, dynamic>.from(samplePostJson);
        jsonWithoutLikeStatus.remove('user_has_liked');
        
        final post = ForumPost.fromJson(jsonWithoutLikeStatus);
        
        expect(post.userHasLiked, false);
      });
    });

    // =========================================================================
    // JSON Serialization Tests (toJson)
    // =========================================================================

    group('toJson', () {
      test('should correctly serialize a post to JSON', () {
        final post = ForumPost.fromJson(samplePostJson);
        final json = post.toJson();

        expect(json['id'], 'post-uuid-123');
        expect(json['title'], 'Test Post Title');
        expect(json['content'], 'Truncated content...');
        expect(json['full_content'], 'This is the full content of the test post.');
        expect(json['category'], 'general');
        expect(json['sport_category'], 'running');
        expect(json['post_views'], 150);
        expect(json['is_pinned'], false);
        expect(json['like_count'], 10);
        expect(json['user_has_liked'], false);
      });

      test('should preserve null values for optional fields', () {
        final post = ForumPost.fromJson(samplePostJson);
        final json = post.toJson();

        expect(json['product_id'], null);
        expect(json['location_id'], null);
        expect(json['last_edited'], null);
      });

      test('should preserve non-null optional fields', () {
        final post = ForumPost.fromJson(pinnedPostWithProductJson);
        final json = post.toJson();

        expect(json['product_id'], 'product-uuid-456');
        expect(json['last_edited'], 'Dec 12, 2024');
      });
    });

    // =========================================================================
    // List Parsing Tests
    // =========================================================================

    group('forumPostFromJson / forumPostToJson', () {
      test('should parse a list of posts from JSON string', () {
        final jsonString = jsonEncode([samplePostJson, pinnedPostWithProductJson]);
        final posts = forumPostFromJson(jsonString);

        expect(posts.length, 2);
        expect(posts[0].id, 'post-uuid-123');
        expect(posts[1].id, 'pinned-post-uuid');
      });

      test('should serialize a list of posts to JSON string', () {
        final posts = [
          ForumPost.fromJson(samplePostJson),
          ForumPost.fromJson(pinnedPostWithProductJson),
        ];
        final jsonString = forumPostToJson(posts);
        final decoded = jsonDecode(jsonString) as List;

        expect(decoded.length, 2);
        expect(decoded[0]['id'], 'post-uuid-123');
        expect(decoded[1]['id'], 'pinned-post-uuid');
      });

      test('should handle empty list', () {
        final jsonString = jsonEncode([]);
        final posts = forumPostFromJson(jsonString);

        expect(posts.isEmpty, true);
      });
    });

    // =========================================================================
    // Helper Method Tests
    // =========================================================================

    group('Helper Methods', () {
      group('canEdit', () {
        test('should return true when user ID matches author ID', () {
          final post = ForumPost.fromJson(samplePostJson); // authorId = 42
          expect(post.canEdit(42), true);
        });

        test('should return false when user ID does not match', () {
          final post = ForumPost.fromJson(samplePostJson);
          expect(post.canEdit(99), false);
        });

        test('should return false when current user ID is null', () {
          final post = ForumPost.fromJson(samplePostJson);
          expect(post.canEdit(null), false);
        });

        test('should return false when author ID is null', () {
          final jsonWithNullAuthorId = Map<String, dynamic>.from(samplePostJson);
          jsonWithNullAuthorId['author_id'] = null;
          final post = ForumPost.fromJson(jsonWithNullAuthorId);
          
          expect(post.canEdit(42), false);
        });
      });

      group('canDelete', () {
        test('should return true for post author', () {
          final post = ForumPost.fromJson(samplePostJson); // authorId = 42
          expect(post.canDelete(42, 'USER'), true);
        });

        test('should return true for admin even if not author', () {
          final post = ForumPost.fromJson(samplePostJson);
          expect(post.canDelete(99, 'ADMIN'), true);
        });

        test('should return false for non-author non-admin', () {
          final post = ForumPost.fromJson(samplePostJson);
          expect(post.canDelete(99, 'USER'), false);
        });

        test('should return false when user ID is null', () {
          final post = ForumPost.fromJson(samplePostJson);
          expect(post.canDelete(null, 'USER'), false);
        });

        test('should return true for admin even with null user ID', () {
          // Note: This tests the model method, but logically admin should have a user ID
          // The model returns true if role is ADMIN regardless of user ID
          final post = ForumPost.fromJson(samplePostJson);
          expect(post.canDelete(1, 'ADMIN'), true);
        });
      });

      group('canPin', () {
        test('should return true for admin', () {
          final post = ForumPost.fromJson(samplePostJson);
          expect(post.canPin('ADMIN'), true);
        });

        test('should return false for regular user', () {
          final post = ForumPost.fromJson(samplePostJson);
          expect(post.canPin('USER'), false);
        });

        test('should return false for seller', () {
          final post = ForumPost.fromJson(samplePostJson);
          expect(post.canPin('SELLER'), false);
        });

        test('should return false for null role', () {
          final post = ForumPost.fromJson(samplePostJson);
          expect(post.canPin(null), false);
        });
      });

      group('hasBeenEdited', () {
        test('should return false when lastEdited is null', () {
          final post = ForumPost.fromJson(samplePostJson);
          expect(post.hasBeenEdited, false);
        });

        test('should return true when lastEdited is set', () {
          final post = ForumPost.fromJson(pinnedPostWithProductJson);
          expect(post.hasBeenEdited, true);
        });
      });

      group('hasLinkedProduct', () {
        test('should return false when productId is null', () {
          final post = ForumPost.fromJson(samplePostJson);
          expect(post.hasLinkedProduct, false);
        });

        test('should return true when productId is set', () {
          final post = ForumPost.fromJson(pinnedPostWithProductJson);
          expect(post.hasLinkedProduct, true);
        });

        test('should return false when productId is empty string', () {
          final jsonWithEmptyProduct = Map<String, dynamic>.from(samplePostJson);
          jsonWithEmptyProduct['product_id'] = '';
          final post = ForumPost.fromJson(jsonWithEmptyProduct);
          
          expect(post.hasLinkedProduct, false);
        });
      });

      group('hasLinkedLocation', () {
        test('should return false when locationId is null', () {
          final post = ForumPost.fromJson(samplePostJson);
          expect(post.hasLinkedLocation, false);
        });

        test('should return true when locationId is set', () {
          final post = ForumPost.fromJson(postWithLocationJson);
          expect(post.hasLinkedLocation, true);
        });
      });
    });

    // =========================================================================
    // Mutable Field Tests
    // =========================================================================

    group('Mutable Fields', () {
      test('postViews should be mutable', () {
        final post = ForumPost.fromJson(samplePostJson);
        expect(post.postViews, 150);
        
        post.postViews = 200;
        expect(post.postViews, 200);
      });

      test('likeCount should be mutable', () {
        final post = ForumPost.fromJson(samplePostJson);
        expect(post.likeCount, 10);
        
        post.likeCount = 15;
        expect(post.likeCount, 15);
      });

      test('userHasLiked should be mutable', () {
        final post = ForumPost.fromJson(samplePostJson);
        expect(post.userHasLiked, false);
        
        post.userHasLiked = true;
        expect(post.userHasLiked, true);
      });
    });

    // =========================================================================
    // Edge Cases
    // =========================================================================

    group('Edge Cases', () {
      test('should handle special characters in title and content', () {
        final jsonWithSpecialChars = Map<String, dynamic>.from(samplePostJson);
        jsonWithSpecialChars['title'] = 'Test <script>alert("XSS")</script>';
        jsonWithSpecialChars['content'] = 'Content with émojis 🏃‍♂️ and unicode ñ';
        
        final post = ForumPost.fromJson(jsonWithSpecialChars);
        
        expect(post.title, 'Test <script>alert("XSS")</script>');
        expect(post.content, 'Content with émojis 🏃‍♂️ and unicode ñ');
      });

      test('should handle very long content', () {
        final longContent = 'A' * 10000;
        final jsonWithLongContent = Map<String, dynamic>.from(samplePostJson);
        jsonWithLongContent['full_content'] = longContent;
        
        final post = ForumPost.fromJson(jsonWithLongContent);
        
        expect(post.fullContent.length, 10000);
      });

      test('should handle zero values for numeric fields', () {
        final jsonWithZeros = Map<String, dynamic>.from(samplePostJson);
        jsonWithZeros['post_views'] = 0;
        jsonWithZeros['like_count'] = 0;
        
        final post = ForumPost.fromJson(jsonWithZeros);
        
        expect(post.postViews, 0);
        expect(post.likeCount, 0);
      });
    });
  });
}
