// =============================================================================
// ForumReply Model Unit Tests
// =============================================================================
// Comprehensive tests for the ForumReply model covering:
// - JSON serialization/deserialization
// - All field mappings
// - QuoteInfo nested model
// - Helper methods (canDelete, hasQuote)
// - Edge cases and null handling
//
// BONUS: Unit Testing with >70% coverage
// =============================================================================

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon_mobile/forum/models/forum_reply.dart';

void main() {
  group('ForumReply Model Tests', () {
    // =========================================================================
    // Test Data
    // =========================================================================

    /// Sample JSON representing a simple reply without quote
    final Map<String, dynamic> simpleReplyJson = {
      'id': 'reply-uuid-123',
      'content': 'This is a test reply.',
      'created_at': 'Dec 14, 2024',
      'author': 'replier',
      'author_id': 42,
      'author_initial': 'R',
      'author_role': 'USER',
      'total_posts': 15,
      'post_id': 'post-uuid-456',
      'post_title': 'Original Post Title',
      'post_sport_category': 'running',
      'quote_info': null,
    };

    /// Sample JSON representing a reply with quote
    final Map<String, dynamic> replyWithQuoteJson = {
      'id': 'reply-uuid-789',
      'content': 'I agree with your point!',
      'created_at': 'Dec 15, 2024',
      'author': 'quoter',
      'author_id': 99,
      'author_initial': 'Q',
      'author_role': 'USER',
      'total_posts': 30,
      'post_id': 'post-uuid-456',
      'post_title': 'Original Post Title',
      'post_sport_category': 'cycling',
      'quote_info': {
        'id': 'quoted-reply-uuid',
        'author': 'original_author',
        'content': 'This is the quoted content...',
      },
    };

    /// Sample JSON for admin reply
    final Map<String, dynamic> adminReplyJson = {
      'id': 'admin-reply-uuid',
      'content': 'This is an official response.',
      'created_at': 'Dec 16, 2024',
      'author': 'admin',
      'author_id': 1,
      'author_initial': 'A',
      'author_role': 'ADMIN',
      'total_posts': 500,
      'post_id': 'post-uuid-456',
      'post_title': 'Original Post Title',
      'post_sport_category': 'swimming',
      'quote_info': null,
    };

    // =========================================================================
    // JSON Parsing Tests (fromJson)
    // =========================================================================

    group('fromJson', () {
      test('should correctly parse a simple reply JSON', () {
        final reply = ForumReply.fromJson(simpleReplyJson);

        expect(reply.id, 'reply-uuid-123');
        expect(reply.content, 'This is a test reply.');
        expect(reply.createdAt, 'Dec 14, 2024');
        expect(reply.author, 'replier');
        expect(reply.authorId, 42);
        expect(reply.authorInitial, 'R');
        expect(reply.authorRole, 'USER');
        expect(reply.totalPosts, 15);
        expect(reply.postId, 'post-uuid-456');
        expect(reply.postTitle, 'Original Post Title');
        expect(reply.postCategory, 'running');
        expect(reply.quoteInfo, null);
      });

      test('should correctly parse a reply with quote', () {
        final reply = ForumReply.fromJson(replyWithQuoteJson);

        expect(reply.id, 'reply-uuid-789');
        expect(reply.quoteInfo, isNotNull);
        expect(reply.quoteInfo!.id, 'quoted-reply-uuid');
        expect(reply.quoteInfo!.author, 'original_author');
        expect(reply.quoteInfo!.content, 'This is the quoted content...');
      });

      test('should correctly parse an admin reply', () {
        final reply = ForumReply.fromJson(adminReplyJson);

        expect(reply.author, 'admin');
        expect(reply.authorRole, 'ADMIN');
        expect(reply.totalPosts, 500);
      });

      test('should handle missing post_id as empty string', () {
        final jsonWithoutPostId = Map<String, dynamic>.from(simpleReplyJson);
        jsonWithoutPostId['post_id'] = null;
        
        final reply = ForumReply.fromJson(jsonWithoutPostId);
        
        expect(reply.postId, '');
      });

      test('should handle missing post_title with default value', () {
        final jsonWithoutPostTitle = Map<String, dynamic>.from(simpleReplyJson);
        jsonWithoutPostTitle['post_title'] = null;
        
        final reply = ForumReply.fromJson(jsonWithoutPostTitle);
        
        expect(reply.postTitle, 'Unknown Post');
      });

      test('should handle missing post_sport_category with empty string', () {
        final jsonWithoutCategory = Map<String, dynamic>.from(simpleReplyJson);
        jsonWithoutCategory['post_sport_category'] = null;
        
        final reply = ForumReply.fromJson(jsonWithoutCategory);
        
        expect(reply.postCategory, '');
      });

      test('should handle numeric post_id', () {
        final jsonWithNumericPostId = Map<String, dynamic>.from(simpleReplyJson);
        jsonWithNumericPostId['post_id'] = 123;
        
        final reply = ForumReply.fromJson(jsonWithNumericPostId);
        
        expect(reply.postId, '123');
      });
    });

    // =========================================================================
    // JSON Serialization Tests (toJson)
    // =========================================================================

    group('toJson', () {
      test('should correctly serialize a simple reply to JSON', () {
        final reply = ForumReply.fromJson(simpleReplyJson);
        final json = reply.toJson();

        expect(json['id'], 'reply-uuid-123');
        expect(json['content'], 'This is a test reply.');
        expect(json['created_at'], 'Dec 14, 2024');
        expect(json['author'], 'replier');
        expect(json['author_id'], 42);
        expect(json['author_initial'], 'R');
        expect(json['author_role'], 'USER');
        expect(json['total_posts'], 15);
        expect(json['post_id'], 'post-uuid-456');
        expect(json['post_title'], 'Original Post Title');
        expect(json['post_sport_category'], 'running');
        expect(json['quote_info'], null);
      });

      test('should correctly serialize a reply with quote to JSON', () {
        final reply = ForumReply.fromJson(replyWithQuoteJson);
        final json = reply.toJson();

        expect(json['quote_info'], isNotNull);
        expect(json['quote_info']['id'], 'quoted-reply-uuid');
        expect(json['quote_info']['author'], 'original_author');
        expect(json['quote_info']['content'], 'This is the quoted content...');
      });
    });

    // =========================================================================
    // List Parsing Tests
    // =========================================================================

    group('forumReplyFromJson / forumReplyToJson', () {
      test('should parse a list of replies from JSON string', () {
        final jsonString = jsonEncode([simpleReplyJson, replyWithQuoteJson]);
        final replies = forumReplyFromJson(jsonString);

        expect(replies.length, 2);
        expect(replies[0].id, 'reply-uuid-123');
        expect(replies[1].id, 'reply-uuid-789');
        expect(replies[1].hasQuote, true);
      });

      test('should serialize a list of replies to JSON string', () {
        final replies = [
          ForumReply.fromJson(simpleReplyJson),
          ForumReply.fromJson(replyWithQuoteJson),
        ];
        final jsonString = forumReplyToJson(replies);
        final decoded = jsonDecode(jsonString) as List;

        expect(decoded.length, 2);
        expect(decoded[0]['id'], 'reply-uuid-123');
        expect(decoded[1]['id'], 'reply-uuid-789');
      });

      test('should handle empty list', () {
        final jsonString = jsonEncode([]);
        final replies = forumReplyFromJson(jsonString);

        expect(replies.isEmpty, true);
      });
    });

    // =========================================================================
    // Helper Method Tests
    // =========================================================================

    group('Helper Methods', () {
      group('hasQuote', () {
        test('should return false when quoteInfo is null', () {
          final reply = ForumReply.fromJson(simpleReplyJson);
          expect(reply.hasQuote, false);
        });

        test('should return true when quoteInfo is present', () {
          final reply = ForumReply.fromJson(replyWithQuoteJson);
          expect(reply.hasQuote, true);
        });
      });

      group('canDelete', () {
        test('should return true for reply author', () {
          final reply = ForumReply.fromJson(simpleReplyJson); // authorId = 42
          expect(reply.canDelete(42, 'USER'), true);
        });

        test('should return true for admin even if not author', () {
          final reply = ForumReply.fromJson(simpleReplyJson);
          expect(reply.canDelete(99, 'ADMIN'), true);
        });

        test('should return false for non-author non-admin', () {
          final reply = ForumReply.fromJson(simpleReplyJson);
          expect(reply.canDelete(99, 'USER'), false);
        });

        test('should return false when user ID is null', () {
          final reply = ForumReply.fromJson(simpleReplyJson);
          expect(reply.canDelete(null, 'USER'), false);
        });

        test('should return false when author ID is null and not admin', () {
          final jsonWithNullAuthorId = Map<String, dynamic>.from(simpleReplyJson);
          jsonWithNullAuthorId['author_id'] = null;
          final reply = ForumReply.fromJson(jsonWithNullAuthorId);
          
          expect(reply.canDelete(42, 'USER'), false);
        });

        test('should return true for admin even when author ID is null', () {
          final jsonWithNullAuthorId = Map<String, dynamic>.from(simpleReplyJson);
          jsonWithNullAuthorId['author_id'] = null;
          final reply = ForumReply.fromJson(jsonWithNullAuthorId);
          
          expect(reply.canDelete(1, 'ADMIN'), true);
        });
      });
    });

    // =========================================================================
    // Mutable Field Tests
    // =========================================================================

    group('Mutable Fields', () {
      test('id should be mutable', () {
        final reply = ForumReply.fromJson(simpleReplyJson);
        reply.id = 'new-id';
        expect(reply.id, 'new-id');
      });

      test('content should be mutable', () {
        final reply = ForumReply.fromJson(simpleReplyJson);
        reply.content = 'Updated content';
        expect(reply.content, 'Updated content');
      });

      test('createdAt should be mutable', () {
        final reply = ForumReply.fromJson(simpleReplyJson);
        reply.createdAt = 'Dec 20, 2024';
        expect(reply.createdAt, 'Dec 20, 2024');
      });

      test('author should be mutable', () {
        final reply = ForumReply.fromJson(simpleReplyJson);
        reply.author = 'newauthor';
        expect(reply.author, 'newauthor');
      });

      test('authorId should be mutable', () {
        final reply = ForumReply.fromJson(simpleReplyJson);
        reply.authorId = 100;
        expect(reply.authorId, 100);
      });

      test('authorInitial should be mutable', () {
        final reply = ForumReply.fromJson(simpleReplyJson);
        reply.authorInitial = 'N';
        expect(reply.authorInitial, 'N');
      });

      test('authorRole should be mutable', () {
        final reply = ForumReply.fromJson(simpleReplyJson);
        reply.authorRole = 'ADMIN';
        expect(reply.authorRole, 'ADMIN');
      });

      test('totalPosts should be mutable', () {
        final reply = ForumReply.fromJson(simpleReplyJson);
        reply.totalPosts = 100;
        expect(reply.totalPosts, 100);
      });

      test('postId should be mutable', () {
        final reply = ForumReply.fromJson(simpleReplyJson);
        reply.postId = 'new-post-id';
        expect(reply.postId, 'new-post-id');
      });

      test('postTitle should be mutable', () {
        final reply = ForumReply.fromJson(simpleReplyJson);
        reply.postTitle = 'New Post Title';
        expect(reply.postTitle, 'New Post Title');
      });

      test('postCategory should be mutable', () {
        final reply = ForumReply.fromJson(simpleReplyJson);
        reply.postCategory = 'cycling';
        expect(reply.postCategory, 'cycling');
      });
    });

    // =========================================================================
    // Edge Cases
    // =========================================================================

    group('Edge Cases', () {
      test('should handle special characters in content', () {
        final jsonWithSpecialChars = Map<String, dynamic>.from(simpleReplyJson);
        jsonWithSpecialChars['content'] = 'Reply with émojis 🏃‍♂️ and <html>tags</html>';
        
        final reply = ForumReply.fromJson(jsonWithSpecialChars);
        
        expect(reply.content, 'Reply with émojis 🏃‍♂️ and <html>tags</html>');
      });

      test('should handle very long content', () {
        final longContent = 'B' * 5000;
        final jsonWithLongContent = Map<String, dynamic>.from(simpleReplyJson);
        jsonWithLongContent['content'] = longContent;
        
        final reply = ForumReply.fromJson(jsonWithLongContent);
        
        expect(reply.content.length, 5000);
      });

      test('should handle zero total posts', () {
        final jsonWithZeroPosts = Map<String, dynamic>.from(simpleReplyJson);
        jsonWithZeroPosts['total_posts'] = 0;
        
        final reply = ForumReply.fromJson(jsonWithZeroPosts);
        
        expect(reply.totalPosts, 0);
      });
    });
  });

  // ===========================================================================
  // QuoteInfo Model Tests
  // ===========================================================================

  group('QuoteInfo Model Tests', () {
    /// Sample QuoteInfo JSON
    final Map<String, dynamic> quoteInfoJson = {
      'id': 'quote-uuid-123',
      'author': 'quoted_author',
      'content': 'This is the quoted text.',
    };

    group('fromJson', () {
      test('should correctly parse QuoteInfo JSON', () {
        final quoteInfo = QuoteInfo.fromJson(quoteInfoJson);

        expect(quoteInfo.id, 'quote-uuid-123');
        expect(quoteInfo.author, 'quoted_author');
        expect(quoteInfo.content, 'This is the quoted text.');
      });
    });

    group('toJson', () {
      test('should correctly serialize QuoteInfo to JSON', () {
        final quoteInfo = QuoteInfo.fromJson(quoteInfoJson);
        final json = quoteInfo.toJson();

        expect(json['id'], 'quote-uuid-123');
        expect(json['author'], 'quoted_author');
        expect(json['content'], 'This is the quoted text.');
      });
    });

    group('Mutable Fields', () {
      test('id should be mutable', () {
        final quoteInfo = QuoteInfo.fromJson(quoteInfoJson);
        quoteInfo.id = 'new-id';
        expect(quoteInfo.id, 'new-id');
      });

      test('author should be mutable', () {
        final quoteInfo = QuoteInfo.fromJson(quoteInfoJson);
        quoteInfo.author = 'new_author';
        expect(quoteInfo.author, 'new_author');
      });

      test('content should be mutable', () {
        final quoteInfo = QuoteInfo.fromJson(quoteInfoJson);
        quoteInfo.content = 'Updated quoted content';
        expect(quoteInfo.content, 'Updated quoted content');
      });
    });

    group('Edge Cases', () {
      test('should handle truncated quoted content', () {
        final jsonWithTruncated = Map<String, dynamic>.from(quoteInfoJson);
        jsonWithTruncated['content'] = 'This is a very long quote that has been truncated...';
        
        final quoteInfo = QuoteInfo.fromJson(jsonWithTruncated);
        
        expect(quoteInfo.content.endsWith('...'), true);
      });
    });
  });
}
