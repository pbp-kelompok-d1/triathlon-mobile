// =============================================================================
// Forum Cache Service
// =============================================================================
// This service provides caching functionality for forum posts to improve
// performance and reduce unnecessary API calls.
//
// BONUS IMPLEMENTATION: Advanced Performance Optimization
// Features:
// - In-memory caching with TTL (Time To Live)
// - Automatic cache invalidation
// - Cache statistics for debugging
// - Thread-safe operations
//
// This significantly improves user experience by:
// 1. Reducing load times on revisiting forum list
// 2. Decreasing server load
// 3. Enabling offline-capable browsing patterns
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/forum_post.dart';
import '../../config/env_config.dart';

/// Cache entry with timestamp for TTL tracking
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  
  CacheEntry(this.data) : timestamp = DateTime.now();
  
  /// Check if this cache entry has expired
  bool isExpired(Duration ttl) {
    return DateTime.now().difference(timestamp) > ttl;
  }
  
  /// Get age of this cache entry
  Duration get age => DateTime.now().difference(timestamp);
}

/// Service for caching forum data
class ForumCacheService {
  // Private constructor for singleton pattern
  ForumCacheService._();
  
  /// Singleton instance
  static final ForumCacheService instance = ForumCacheService._();
  
  // ===========================================================================
  // Cache Storage
  // ===========================================================================
  
  /// Cached forum posts list
  CacheEntry<List<ForumPost>>? _postsCache;
  
  /// Cached individual post details (by post ID)
  final Map<String, CacheEntry<Map<String, dynamic>>> _postDetailCache = {};
  
  /// Cache statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  
  // ===========================================================================
  // Configuration
  // ===========================================================================
  
  /// Get cache TTL from environment config
  Duration get _cacheTtl => env.cacheDuration;
  
  /// Whether caching is enabled
  bool get _isCacheEnabled => env.enableCache;
  
  // ===========================================================================
  // Posts List Cache
  // ===========================================================================
  
  /// Get cached posts if available and not expired
  List<ForumPost>? getCachedPosts() {
    if (!_isCacheEnabled) return null;
    
    if (_postsCache != null && !_postsCache!.isExpired(_cacheTtl)) {
      _cacheHits++;
      _logCacheAccess('POSTS_LIST', hit: true);
      return _postsCache!.data;
    }
    
    _cacheMisses++;
    _logCacheAccess('POSTS_LIST', hit: false);
    return null;
  }
  
  /// Cache the posts list
  void cachePosts(List<ForumPost> posts) {
    if (!_isCacheEnabled) return;
    
    _postsCache = CacheEntry(posts);
    _logCache('Cached ${posts.length} posts');
  }
  
  /// Invalidate posts cache (call after create/update/delete)
  void invalidatePostsCache() {
    _postsCache = null;
    _logCache('Posts cache invalidated');
  }
  
  // ===========================================================================
  // Post Detail Cache
  // ===========================================================================
  
  /// Get cached post detail if available and not expired
  Map<String, dynamic>? getCachedPostDetail(String postId) {
    if (!_isCacheEnabled) return null;
    
    final entry = _postDetailCache[postId];
    if (entry != null && !entry.isExpired(_cacheTtl)) {
      _cacheHits++;
      _logCacheAccess('POST_DETAIL:$postId', hit: true);
      return entry.data;
    }
    
    _cacheMisses++;
    _logCacheAccess('POST_DETAIL:$postId', hit: false);
    return null;
  }
  
  /// Cache a post detail
  void cachePostDetail(String postId, Map<String, dynamic> data) {
    if (!_isCacheEnabled) return;
    
    _postDetailCache[postId] = CacheEntry(data);
    _logCache('Cached detail for post: $postId');
  }
  
  /// Invalidate a specific post detail cache
  void invalidatePostDetail(String postId) {
    _postDetailCache.remove(postId);
    _logCache('Post detail cache invalidated: $postId');
  }
  
  // ===========================================================================
  // Cache Management
  // ===========================================================================
  
  /// Clear all caches
  void clearAll() {
    _postsCache = null;
    _postDetailCache.clear();
    _logCache('All caches cleared');
  }
  
  /// Remove expired entries from detail cache
  void cleanupExpiredEntries() {
    _postDetailCache.removeWhere((_, entry) => entry.isExpired(_cacheTtl));
    _logCache('Expired entries cleaned up');
  }
  
  // ===========================================================================
  // Cache Statistics
  // ===========================================================================
  
  /// Get cache statistics for debugging
  Map<String, dynamic> get statistics => {
    'enabled': _isCacheEnabled,
    'ttl_seconds': _cacheTtl.inSeconds,
    'cache_hits': _cacheHits,
    'cache_misses': _cacheMisses,
    'hit_rate': _cacheHits + _cacheMisses > 0
        ? (_cacheHits / (_cacheHits + _cacheMisses) * 100).toStringAsFixed(1)
        : '0.0',
    'posts_cached': _postsCache != null,
    'posts_cache_age': _postsCache?.age.inSeconds,
    'detail_cache_entries': _postDetailCache.length,
  };
  
  /// Reset statistics
  void resetStatistics() {
    _cacheHits = 0;
    _cacheMisses = 0;
  }
  
  // ===========================================================================
  // Logging
  // ===========================================================================
  
  void _logCache(String message) {
    if (env.isDebugMode) {
      debugPrint('📦 [ForumCache] $message');
    }
  }
  
  void _logCacheAccess(String key, {required bool hit}) {
    if (env.isDebugMode) {
      final status = hit ? '✅ HIT' : '❌ MISS';
      debugPrint('📦 [ForumCache] $status: $key');
    }
  }
}

// =============================================================================
// Convenience Getter
// =============================================================================

/// Global accessor for forum cache service
ForumCacheService get forumCache => ForumCacheService.instance;
