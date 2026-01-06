// community/screens/bookmark_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Models
import '../models/post_model.dart';

// Services
import '../services/bookmark_service.dart';

// Widgets - 共享组件
import '../widgets/shared/category_tabs.dart';
import '../widgets/shared/post_list_card.dart';
import '../widgets/shared/list_bottom_actions.dart';

// Common
import '../../common/custom_appbar.dart';
import '../../common/custom_footer.dart';
import '../../common/custom_drawer.dart';
import '../../common/app_colors.dart';

// Screens
import 'community_detail_screen.dart';
import '../../recipes/ingreCheck_screen.dart';
import '../../auth/home_screen.dart';
import '../../auth/auth_provider.dart';

class BookmarkListScreen extends StatefulWidget {
  const BookmarkListScreen({Key? key}) : super(key: key);

  @override
  State<BookmarkListScreen> createState() => _BookmarkListScreenState();
}

class _BookmarkListScreenState extends State<BookmarkListScreen> {
  // ========== 변수 선언 ==========
  final BookmarkService _bookmarkService = BookmarkService();

  List<Post> _bookmarkedPosts = [];
  bool _isLoading = false;

  String _selectedCategory = '전체';
  final List<String> _categories = ['전체', '자유게시판', '문의사항'];

  Set<String> _selectedPostIds = {};
  bool _isSelectionMode = false;

  // ========== 초기화 ==========
  @override
  void initState() {
    super.initState();
    _loadBookmarkedPosts();
  }

  // ========== 데이터 로드 ==========
  Future<void> _loadBookmarkedPosts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final posts = await _bookmarkService.getBookmarkedPosts(
        currentUser.uid,
        category: _selectedCategory == '전체' ? null : _selectedCategory,
      );

      setState(() {
        _bookmarkedPosts = posts;
        _isLoading = false;
        _selectedPostIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      print('북마크 로딩 실패: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크를 불러오는데 실패했습니다')),
        );
      }
    }
  }

  // ========== 分类切换 ==========
  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadBookmarkedPosts();
  }

  // ========== 书签操作 ==========
  void _handleBookmarkRemove() {
    if (_isSelectionMode && _selectedPostIds.isNotEmpty) {
      _removeSelectedBookmarks();
    } else if (_isSelectionMode && _selectedPostIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제할 항목을 선택해주세요')),
      );
    } else {
      setState(() {
        _isSelectionMode = true;
      });
    }
  }

  Future<void> _removeSelectedBookmarks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('북마크 해제'),
        content: Text('선택한 ${_selectedPostIds.length}개의 북마크를 해제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('해제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final successCount = await _bookmarkService.removeMultipleBookmarks(
        currentUser.uid,
        _selectedPostIds.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$successCount개의 북마크가 해제되었습니다')),
        );
        await _loadBookmarkedPosts();
      }
    } catch (e) {
      print('북마크 해제 실패: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크 해제에 실패했습니다')),
        );
      }
    }
  }

  // ========== 卡片点击 ==========
  void _handleCardTap(Post post) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedPostIds.contains(post.id)) {
          _selectedPostIds.remove(post.id);
        } else {
          _selectedPostIds.add(post.id);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(postId: post.id),
        ),
      ).then((_) => _loadBookmarkedPosts());
    }
  }

  // ========== 底部操作 ==========
  void _handleSecondaryAction() {
    if (_isSelectionMode) {
      setState(() {
        _isSelectionMode = false;
        _selectedPostIds.clear();
      });
    } else {
      Navigator.pop(context);
    }
  }

  // ========== Footer 导航 ==========
  void _handleFooterTap(int index) {
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(initialIndex: 2),
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(initialIndex: 1),
        ),
      );
    } else if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen(initialIndex: 0)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('해당 기능은 개발 중입니다')),
      );
    }
  }

  // ========== UI 构建 ==========
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    return Scaffold(
      appBar: CustomAppBar(appName: '북마크 목록'),
      drawer: CustomDrawer(),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 直接从 CategoryTabs 开始，删除上面的空 Container
          CategoryTabs(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategoryChanged: _onCategoryChanged,
          ),

          Divider(height: 1, color: Colors.grey[300]),

          // 帖子列表
          Expanded(child: _buildPostList(currentUser)),
        ],
      ),
      bottomSheet: ListBottomActions(
        actionType: ListActionType.bookmark,  // 添加这行
        isSelectionMode: _isSelectionMode,
        selectedCount: _selectedPostIds.length,
        onPrimaryAction: _handleBookmarkRemove,
        onSecondaryAction: _handleSecondaryAction,
      ),
      // bottomNavigationBar: CustomFooter(
      //   currentIndex: 2,
      //   onTap: _handleFooterTap,
      // ),
    );
  }

  /// 帖子列表
  Widget _buildPostList(currentUser) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_bookmarkedPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '북마크한 게시글이 없습니다',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _bookmarkedPosts.length,
      itemBuilder: (context, index) {
        final post = _bookmarkedPosts[index];
        final isSelected = _selectedPostIds.contains(post.id);

        return PostListCard(
          post: post,
          actionType: PostCardActionType.bookmark,  // 添加这行
          isSelected: isSelected,
          isSelectionMode: _isSelectionMode,
          onTap: () => _handleCardTap(post),
          currentUserId: currentUser?.uid,
          onBookmarkRemove: () async {
            if (currentUser != null) {
              await _bookmarkService.removeBookmark(
                currentUser.uid,
                post.id,
              );
              _loadBookmarkedPosts();
            }
          },
        );
      },
    );
  }
}