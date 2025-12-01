import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../widgets/left_drawer.dart';
import '../models/forum_post.dart';
import 'forum_detail.dart';
import 'forum_form.dart';

class ForumListPage extends StatefulWidget {
  const ForumListPage({super.key});

  @override
  State<ForumListPage> createState() => _ForumListPageState();
}

class _ForumListPageState extends State<ForumListPage> {
  String _selectedCategory = 'all';
  String _selectedSportCategory = 'all';

  Future<List<ForumPost>> fetchForumPosts(CookieRequest request) async {
    final response = await request.get('$baseUrl/forum/json/');
    
    List<ForumPost> posts = [];
    for (var d in response) {
      if (d != null) {
        posts.add(ForumPost.fromJson(d));
      }
    }
    return posts;
  }

  List<ForumPost> _filterPosts(List<ForumPost> posts) {
    return posts.where((post) {
      bool categoryMatch = _selectedCategory == 'all' || 
                          post.category == _selectedCategory;
      bool sportMatch = _selectedSportCategory == 'all' || 
                       post.sportCategory == _selectedSportCategory;
      return categoryMatch && sportMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value.startsWith('cat_')) {
                  _selectedCategory = value.substring(4);
                } else if (value.startsWith('sport_')) {
                  _selectedSportCategory = value.substring(6);
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'cat_all',
                child: Text('All Categories'),
              ),
              const PopupMenuItem(
                value: 'cat_general',
                child: Text('General Discussion'),
              ),
              const PopupMenuItem(
                value: 'cat_product_review',
                child: Text('Product Review'),
              ),
              const PopupMenuItem(
                value: 'cat_location_review',
                child: Text('Location Review'),
              ),
              const PopupMenuItem(
                value: 'cat_question',
                child: Text('Question'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'sport_all',
                child: Text('All Sports'),
              ),
              const PopupMenuItem(
                value: 'sport_running',
                child: Text('Running'),
              ),
              const PopupMenuItem(
                value: 'sport_cycling',
                child: Text('Cycling'),
              ),
              const PopupMenuItem(
                value: 'sport_swimming',
                child: Text('Swimming'),
              ),
            ],
          ),
        ],
      ),
      drawer: const LeftDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ForumFormPage()),
          );
        },
        backgroundColor: const Color(0xFF1D4ED8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<ForumPost>>(
        future: fetchForumPosts(request),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No forum posts yet.',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Be the first to start a discussion!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final filteredPosts = _filterPosts(snapshot.data!);

          if (filteredPosts.isEmpty) {
            return const Center(
              child: Text(
                'No posts match your filters.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredPosts.length,
            itemBuilder: (context, index) {
              final post = filteredPosts[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ForumDetailPage(postId: post.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (post.isPinned)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.push_pin,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                post.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Chip(
                              label: Text(
                                post.categoryDisplay,
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: Colors.blue[50],
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            Chip(
                              label: Text(
                                post.sportCategoryDisplay,
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: Colors.green[50],
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF1D4ED8),
                              child: Text(
                                post.authorInitial,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              post.author,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.visibility,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${post.postViews}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.favorite,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${post.likeCount}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          post.createdAt,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
