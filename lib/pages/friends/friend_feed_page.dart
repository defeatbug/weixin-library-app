import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/social_api.dart';
import '../../helpers/graphql_helper.dart';
import '../../models/review.dart';

class FriendFeedPage extends StatefulWidget {
  const FriendFeedPage({super.key});

  @override
  State<FriendFeedPage> createState() => _FriendFeedPageState();
}

class _FriendFeedPageState extends State<FriendFeedPage> {
  final List<Review> _reviews = [];
  bool _isLoading = true;
  bool _isInitialLoading = true;
  bool _hasMore = true;
  bool _hasError = false;
  int _page = 0;
  static const _pageSize = 20;

  final List<String> _tabs = ['推荐', '关注', '闲聊', '话题', '我的'];
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final result = await SocialApi.getRecentReviews(page: _page, size: _pageSize);
      if (!mounted) return;

      final items = GraphQLHelper.getItemsFromResult(
        result, Review.fromJson, ['recentReviews', 'items'],
      );
      final total = result.data?['recentReviews']?['total'] as num? ?? 0;

      setState(() {
        _reviews.addAll(items);
        _page++;
        _hasMore = _reviews.length < total;
        _isLoading = false;
        _isInitialLoading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isInitialLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _refresh() async {
    _page = 0;
    _reviews.clear();
    _hasMore = true;
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('书友'),
      ),
      body: Column(
        children: [
          // Sub-tabs
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 24),
              itemBuilder: (context, index) {
                final selected = _activeTab == index;
                return GestureDetector(
                  onTap: () => setState(() => _activeTab = index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _tabs[index],
                        style: TextStyle(
                          fontSize: selected ? 16 : 15,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          color: selected
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (selected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 20, height: 3,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Feed content
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError && _reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('加载失败', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton.tonal(onPressed: _refresh, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('暂无书友动态', style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('去评价一本书，分享你的想法',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >= notification.metrics.maxScrollExtent - 300) {
            _loadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _reviews.length + (_isLoading ? 1 : 0),
          separatorBuilder: (_, __) => const Divider(height: 24),
          itemBuilder: (context, index) {
            if (index >= _reviews.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return _FeedCard(review: _reviews[index]);
          },
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final Review review;

  const _FeedCard({required this.review});

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/book/${review.book.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name + time
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  review.user.displayName.isNotEmpty
                      ? review.user.displayName[0]
                      : '?',
                  style: TextStyle(
                    fontSize: 14, color: theme.colorScheme.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.user.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Rating stars
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < review.rating ? Icons.star : Icons.star_border,
                size: 14,
                color: Colors.amber[700],
              );
            }),
          ),

          const SizedBox(height: 6),

          // Content
          if (review.content != null && review.content!.isNotEmpty)
            Text(
              review.content!,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface,
              ),
            ),

          const SizedBox(height: 8),

          // Book reference
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_stories, size: 14,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  '《${review.book.title}》',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
