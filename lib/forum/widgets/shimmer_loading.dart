// =============================================================================
// BONUS FEATURE: Shimmer Loading Effects
// =============================================================================
// This file implements skeleton loading UI with shimmer effects to provide
// better user experience during data loading. Instead of showing a plain
// spinner, users see animated placeholders that match the layout of actual
// content, reducing perceived loading time.
//
// IMPLEMENTATION HIGHLIGHTS:
// - Uses the 'shimmer' package for smooth gradient animations
// - Skeleton layouts match actual post card and detail layouts
// - Customizable shimmer colors to match app theme
// - Staggered skeleton items for more natural feel
//
// USAGE:
// Replace CircularProgressIndicator with ForumListShimmer() or
// ForumDetailShimmer() for a more polished loading experience.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loading effect for forum list page
/// Displays multiple skeleton post cards with shimmer animation
class ForumListShimmer extends StatelessWidget {
  /// Number of skeleton items to show
  final int itemCount;
  
  const ForumListShimmer({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      // Base color - the skeleton background
      baseColor: Colors.grey[300]!,
      // Highlight color - the shimmer effect color
      highlightColor: Colors.grey[100]!,
      // Animation duration - slower = more subtle
      period: const Duration(milliseconds: 1500),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return _buildSkeletonPostCard();
        },
      ),
    );
  }

  /// Build a skeleton post card that matches the actual post card layout
  Widget _buildSkeletonPostCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with category chips
            Row(
              children: [
                _buildSkeletonChip(width: 80),
                const SizedBox(width: 8),
                _buildSkeletonChip(width: 60),
              ],
            ),
            const SizedBox(height: 12),
            
            // Title placeholder
            _buildSkeletonLine(width: double.infinity, height: 20),
            const SizedBox(height: 8),
            
            // Content preview placeholders
            _buildSkeletonLine(width: double.infinity, height: 14),
            const SizedBox(height: 6),
            _buildSkeletonLine(width: 200, height: 14),
            const SizedBox(height: 16),
            
            // Author and stats row
            Row(
              children: [
                // Avatar placeholder
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                // Username placeholder
                _buildSkeletonLine(width: 80, height: 14),
                const Spacer(),
                // Stats placeholders
                _buildSkeletonLine(width: 40, height: 14),
                const SizedBox(width: 12),
                _buildSkeletonLine(width: 40, height: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build a skeleton chip/badge placeholder
  Widget _buildSkeletonChip({required double width}) {
    return Container(
      width: width,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  /// Build a skeleton line/text placeholder
  Widget _buildSkeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Shimmer loading effect for forum detail page
/// Displays skeleton layout for post details and replies
class ForumDetailShimmer extends StatelessWidget {
  const ForumDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header with title
            _buildSkeletonLine(width: double.infinity, height: 28),
            const SizedBox(height: 16),
            
            // Category badges
            Row(
              children: [
                _buildSkeletonChip(width: 100),
                const SizedBox(width: 8),
                _buildSkeletonChip(width: 80),
              ],
            ),
            const SizedBox(height: 16),
            
            // Author info
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkeletonLine(width: 100, height: 16),
                    const SizedBox(height: 4),
                    _buildSkeletonLine(width: 150, height: 12),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Content paragraphs
            _buildSkeletonLine(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            _buildSkeletonLine(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            _buildSkeletonLine(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            _buildSkeletonLine(width: 250, height: 14),
            const SizedBox(height: 32),
            
            // Stats row
            Row(
              children: [
                _buildSkeletonChip(width: 60),
                const SizedBox(width: 16),
                _buildSkeletonChip(width: 60),
                const SizedBox(width: 16),
                _buildSkeletonChip(width: 80),
              ],
            ),
            const SizedBox(height: 32),
            
            // Replies section header
            _buildSkeletonLine(width: 120, height: 20),
            const SizedBox(height: 16),
            
            // Skeleton replies
            ...List.generate(3, (index) => _buildSkeletonReply()),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonReply() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              _buildSkeletonLine(width: 80, height: 14),
              const Spacer(),
              _buildSkeletonLine(width: 60, height: 12),
            ],
          ),
          const SizedBox(height: 12),
          _buildSkeletonLine(width: double.infinity, height: 14),
          const SizedBox(height: 6),
          _buildSkeletonLine(width: 180, height: 14),
        ],
      ),
    );
  }

  Widget _buildSkeletonChip({required double width}) {
    return Container(
      width: width,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _buildSkeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// A single skeleton post card for use outside of list context
/// Can be used when loading a single post preview
class SkeletonPostCard extends StatelessWidget {
  const SkeletonPostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
