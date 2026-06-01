import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/social_api.dart';
import '../../config/app_colors.dart';
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
  int _mainTab = 1; // 0=有声书, 1=书友

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final result =
          await SocialApi.getRecentReviews(page: _page, size: _pageSize);
      if (!mounted) return;

      final items = GraphQLHelper.getItemsFromResult(
        result,
        Review.fromJson,
        ['recentReviews', 'items'],
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainTabs(),
            _buildSubTabs(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _mainTabButton('有声书', 0),
          const SizedBox(width: 20),
          _mainTabButton('书友', 1),
        ],
      ),
    );
  }

  Widget _mainTabButton(String label, int index) {
    final selected = _mainTab == index;
    return GestureDetector(
      onTap: () => setState(() => _mainTab = index),
      child: Text(
        label,
        style: TextStyle(
          fontSize: selected ? 20 : 16,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? AppColors.primary : AppColors.textHint,
        ),
      ),
    );
  }

  Widget _buildSubTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.searchBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 2),
                itemBuilder: (context, index) {
                  final selected = _activeTab == index;
                  return GestureDetector(
                    onTap: () => setState(() => _activeTab = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.card : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        _tabs[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.searchBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.add, size: 20, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_hasError && _reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off,
                size: 48, color: AppColors.textHint.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('加载失败'),
            const SizedBox(height: 12),
            TextButton(onPressed: _refresh, child: Text('重试')),
          ],
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 64, color: AppColors.textHint.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              '暂无书友动态',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '去评价一本书，分享你的想法',
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 300) {
            _loadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: _reviews.length + (_isLoading ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index >= _reviews.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
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
    return GestureDetector(
      onTap: () => context.push('/book/${review.book.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: review.user.avatarUrl != null
                      ? NetworkImage(review.user.avatarUrl!)
                      : null,
                  child: review.user.avatarUrl == null
                      ? Text(
                          review.user.displayName.isNotEmpty
                              ? review.user.displayName[0]
                              : '?',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    review.user.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  _formatDate(review.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (review.content != null && review.content!.isNotEmpty)
              Text(
                review.content!,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.textPrimary,
                ),
              ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.searchBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '书友 >',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _actionIcon(Icons.share_outlined),
                const Spacer(),
                _actionIcon(Icons.chat_bubble_outline, count: 0),
                const SizedBox(width: 24),
                _actionIcon(Icons.favorite_border, count: 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, {int? count}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.textHint),
        if (count != null && count > 0) ...[
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ],
    );
  }
}
