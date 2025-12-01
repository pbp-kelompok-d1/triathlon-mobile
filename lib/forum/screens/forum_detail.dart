import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../models/forum_reply.dart';

class ForumDetailPage extends StatefulWidget {
  final String postId;

  const ForumDetailPage({super.key, required this.postId});

  @override
  State<ForumDetailPage> createState() => _ForumDetailPageState();
}

class _ForumDetailPageState extends State<ForumDetailPage> {
  final TextEditingController _replyController = TextEditingController();
  Map<String, dynamic>? _postData;
  List<ForumReply> _replies = [];
  bool _isLoading = true;
  bool _userHasLiked = false;

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  Future<void> _loadPostData() async {
    final request = context.read<CookieRequest>();
    try {
      final response =
          await request.get('$baseUrl/forum/${widget.postId}/?format=json');
      setState(() {
        _postData = response['post'];
        _userHasLiked = response['user_has_liked'] ?? false;
        _replies = (response['replies'] as List)
            .map((r) => ForumReply.fromJson(r))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading post: $e')),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(
        '$baseUrl/forum/${widget.postId}/like/',
        {},
      );
      if (response['success']) {
        setState(() {
          _userHasLiked = response['liked'];
          _postData!['like_count'] = response['like_count'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;

    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(
        '$baseUrl/forum/${widget.postId}/reply/',
        {'content': _replyController.text},
      );
      if (response['success']) {
        _replyController.clear();
        await _loadPostData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reply posted!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting reply: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Forum Post'),
          backgroundColor: const Color(0xFF1D4ED8),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_postData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Forum Post'),
          backgroundColor: const Color(0xFF1D4ED8),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Post not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum Post'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post header
                  Row(
                    children: [
                      if (_postData!['is_pinned'] == true)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.push_pin,
                              size: 20, color: Colors.orange),
                        ),
                      Expanded(
                        child: Text(
                          _postData!['title'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(_postData!['category_display']),
                        backgroundColor: Colors.blue[50],
                      ),
                      Chip(
                        label: Text(_postData!['sport_category_display']),
                        backgroundColor: Colors.green[50],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Author info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF1D4ED8),
                        child: Text(
                          _postData!['author_initial'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _postData!['author'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _postData!['created_at'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Post content
                  Text(
                    _postData!['full_content'],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  // Like button and stats
                  Row(
                    children: [
                      IconButton(
                        onPressed: _toggleLike,
                        icon: Icon(
                          _userHasLiked ? Icons.favorite : Icons.favorite_border,
                          color: _userHasLiked ? Colors.red : Colors.grey,
                        ),
                      ),
                      Text('${_postData!['like_count']} likes'),
                      const SizedBox(width: 24),
                      Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${_postData!['post_views']} views'),
                    ],
                  ),
                  const Divider(height: 32),
                  // Replies section
                  Text(
                    'Replies (${_replies.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._replies.map((reply) => _buildReplyCard(reply)),
                ],
              ),
            ),
          ),
          // Reply input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: const InputDecoration(
                      hintText: 'Write a reply...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _submitReply,
                  icon: const Icon(Icons.send),
                  color: const Color(0xFF1D4ED8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyCard(ForumReply reply) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF1D4ED8),
                  child: Text(
                    reply.authorInitial,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.author,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      reply.createdAt,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (reply.quoteInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border(
                    left: BorderSide(color: Colors.grey[400]!, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.quoteInfo!.author,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      reply.quoteInfo!.content,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            Text(reply.content),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }
}
