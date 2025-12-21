// =============================================================================
// ForumCacheService Unit Tests
// =============================================================================
// Tests for the ForumCacheService covering:
// - Singleton pattern
// - Cache storage and retrieval
// - Cache invalidation
// - Post detail caching
// - Statistics tracking
//
// BONUS: Unit Testing with >70% coverage
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:triathlon_mobile/forum/services/forum_cache_service.dart';
import 'package:triathlon_mobile/forum/models/forum_post.dart';
import 'package:triathlon_mobile/config/env_config.dart';

void main() {
  // Load env before all tests
  setUpAll(() async {
    await env.load();
  });
  // Sample test data factory
  ForumPost createTestPost({
    String id = '1',
    String title = 'Test Post',
    String content = 'Test Content',
    String author = 'testuser',
    bool isPinned = false,
    int postViews = 0,
  }) {
    return ForumPost(
      id: id,
      title: title,
      content: content,
      fullContent: content,
      author: author,
      authorId: 1,
      authorInitial: author.isNotEmpty ? author[0].toUpperCase() : 'U',
      authorRole: 'USER',
      category: 'general_discussion',
      categoryDisplay: 'General Discussion',
      sportCategory: 'general',
      sportCategoryDisplay: 'General',
      createdAt: DateTime.now().toIso8601String(),
      isPinned: isPinned,
      postViews: postViews,
      likeCount: 0,
      userHasLiked: false,
    );
  }

  group('ForumCacheService Tests', () {
    // =========================================================================
    // Singleton Pattern Tests
    // =========================================================================

    group('Singleton Pattern', () {
      test('instance should return singleton', () {
        final instance1 = ForumCacheService.instance;
        final instance2 = ForumCacheService.instance;
        
        expect(identical(instance1, instance2), true);
      });

      test('forumCache getter should return same instance', () {
        final cacheInstance = forumCache;
        final directInstance = ForumCacheService.instance;
        
        expect(identical(cacheInstance, directInstance), true);
      });
    });

    // =========================================================================
    // Basic Cache Operations
    // =========================================================================

    group('Basic Cache Operations', () {
      setUp(() {
        // Clear cache before each test
        forumCache.clearAll();
        forumCache.resetStatistics();
      });

      test('should return null when cache is empty', () {
        final cached = forumCache.getCachedPosts();
        expect(cached, isNull);
      });

      test('should store and retrieve posts', () {
        final posts = [createTestPost(id: '1'), createTestPost(id: '2')];
        
        forumCache.cachePosts(posts);
        
        final cached = forumCache.getCachedPosts();
        expect(cached, isNotNull);
        expect(cached!.length, 2);
      });

      test('should return correct posts from cache', () {
        final posts = [
          createTestPost(id: '1', title: 'First Post'),
          createTestPost(id: '2', title: 'Second Post'),
        ];
        
        forumCache.cachePosts(posts);
        
        final cached = forumCache.getCachedPosts()!;
        expect(cached[0].title, 'First Post');
        expect(cached[1].title, 'Second Post');
      });

      test('should overwrite previous cache', () {
        final oldPosts = [createTestPost(id: '1', title: 'Old Post')];
        final newPosts = [createTestPost(id: '2', title: 'New Post')];
        
        forumCache.cachePosts(oldPosts);
        forumCache.cachePosts(newPosts);
        
        final cached = forumCache.getCachedPosts()!;
        expect(cached.length, 1);
        expect(cached[0].title, 'New Post');
      });
    });

    // =========================================================================
    // Cache Invalidation
    // =========================================================================

    group('Cache Invalidation', () {
      setUp(() {
        forumCache.clearAll();
        forumCache.resetStatistics();
      });

      test('invalidatePostsCache should clear cached posts', () {
        final posts = [createTestPost(id: '1')];
        forumCache.cachePosts(posts);
        
        expect(forumCache.getCachedPosts(), isNotNull);
        
        forumCache.invalidatePostsCache();
        
        expect(forumCache.getCachedPosts(), isNull);
      });

      test('clearAll should remove all cached data', () {
        final posts = [createTestPost(id: '1')];
        forumCache.cachePosts(posts);
        forumCache.cachePostDetail('1', {'test': 'data'});
        
        forumCache.clearAll();
        
        expect(forumCache.getCachedPosts(), isNull);
        expect(forumCache.getCachedPostDetail('1'), isNull);
      });

      test('invalidation should work even when cache is empty', () {
        // Should not throw
        expect(() => forumCache.invalidatePostsCache(), returnsNormally);
      });

      test('clearAll should work even when cache is empty', () {
        // Should not throw
        expect(() => forumCache.clearAll(), returnsNormally);
      });
    });

    // =========================================================================
    // Post Detail Cache
    // =========================================================================

    group('Post Detail Cache', () {
      setUp(() {
        forumCache.clearAll();
        forumCache.resetStatistics();
      });

      test('should cache and retrieve post detail', () {
        final detail = {'id': '1', 'title': 'Test', 'content': 'Content'};
        
        forumCache.cachePostDetail('1', detail);
        
        final cached = forumCache.getCachedPostDetail('1');
        expect(cached, isNotNull);
        expect(cached!['title'], 'Test');
      });

      test('should return null for non-cached post detail', () {
        expect(forumCache.getCachedPostDetail('nonexistent'), isNull);
      });

      test('should invalidate specific post detail', () {
        forumCache.cachePostDetail('1', {'test': 'data1'});
        forumCache.cachePostDetail('2', {'test': 'data2'});
        
        forumCache.invalidatePostDetail('1');
        
        expect(forumCache.getCachedPostDetail('1'), isNull);
      });
    });

    // =========================================================================
    // Statistics
    // =========================================================================

    group('Statistics', () {
      setUp(() {
        forumCache.clearAll();
        forumCache.resetStatistics();
      });

      test('statistics should contain expected keys', () {
        final stats = forumCache.statistics;
        
        expect(stats.containsKey('enabled'), true);
        expect(stats.containsKey('ttl_seconds'), true);
        expect(stats.containsKey('cache_hits'), true);
        expect(stats.containsKey('cache_misses'), true);
        expect(stats.containsKey('hit_rate'), true);
        expect(stats.containsKey('posts_cached'), true);
        expect(stats.containsKey('detail_cache_entries'), true);
      });

      test('statistics should show posts_cached as true after caching', () {
        final posts = [createTestPost(id: '1')];
        forumCache.cachePosts(posts);
        
        final stats = forumCache.statistics;
        expect(stats['posts_cached'], true);
      });

      test('resetStatistics should clear hit/miss counts', () {
        // Generate some hits/misses
        forumCache.getCachedPosts(); // miss
        forumCache.cachePosts([createTestPost()]);
        forumCache.getCachedPosts(); // hit
        
        forumCache.resetStatistics();
        
        final stats = forumCache.statistics;
        expect(stats['cache_hits'], 0);
        expect(stats['cache_misses'], 0);
      });
    });

    // =========================================================================
    // Edge Cases
    // =========================================================================

    group('Edge Cases', () {
      setUp(() {
        forumCache.clearAll();
        forumCache.resetStatistics();
      });

      test('should handle empty posts list', () {
        forumCache.cachePosts([]);
        
        final cached = forumCache.getCachedPosts();
        expect(cached, isNotNull);
        expect(cached!.isEmpty, true);
      });

      test('should handle large number of posts', () {
        final largePosts = List.generate(
          100,
          (index) => createTestPost(id: index.toString(), title: 'Post $index'),
        );
        
        forumCache.cachePosts(largePosts);
        
        final cached = forumCache.getCachedPosts();
        expect(cached, isNotNull);
        expect(cached!.length, 100);
      });

      test('should preserve post data integrity', () {
        final post = createTestPost(
          id: '42',
          title: 'Special Title',
          content: 'Special Content',
          author: 'specialuser',
          isPinned: true,
          postViews: 999,
        );
        
        forumCache.cachePosts([post]);
        
        final cached = forumCache.getCachedPosts()!.first;
        expect(cached.id, '42');
        expect(cached.title, 'Special Title');
        expect(cached.content, 'Special Content');
        expect(cached.author, 'specialuser');
        expect(cached.isPinned, true);
        expect(cached.postViews, 999);
      });
    });

    // =========================================================================
    // Cleanup Operations
    // =========================================================================

    group('Cleanup Operations', () {
      setUp(() {
        forumCache.clearAll();
        forumCache.resetStatistics();
      });

      test('cleanupExpiredEntries should not throw', () {
        expect(() => forumCache.cleanupExpiredEntries(), returnsNormally);
      });

      test('cleanupExpiredEntries should work with cached entries', () {
        forumCache.cachePostDetail('1', {'test': 'data'});
        
        expect(() => forumCache.cleanupExpiredEntries(), returnsNormally);
      });
    });
  });
}
