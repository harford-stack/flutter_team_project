// community/screens/my_post_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Models
import '../models/post_model.dart';

// Services
import '../services/post_service.dart';

// Widgets - 使用共享组件
import '../widgets/shared/category_tabs.dart';
import '../widgets/shared/post_list_card.dart';
import '../widgets/shared/list_bottom_actions.dart';
import '../../common/custom_appbar.dart';
import '../../common/custom_footer.dart';
import '../../common/custom_drawer.dart';
import '../../common/app_colors.dart';

// Screens
import 'community_detail_screen.dart';
import 'post_editor_screen.dart';
import 'community_list_screen.dart';
import '../../recipes/ingreCheck_screen.dart';
import '../../auth/home_screen.dart';
import '../../auth/auth_provider.dart';

class MyPostListScreen extends StatefulWidget {
  const MyPostListScreen({Key? key}) : super(key: key);

  @override
  State<MyPostListScreen> createState() => _MyPostListScreenState();
}

class _MyPostListScreenState extends State<MyPostListScreen> {
  // ========== 변수 선언 ==========
  final PostService _postService = PostService();

  List<Post> _myPosts = [];
  bool _isLoading = false;

  String _selectedCategory = '전체';
  final List<String> _categories = ['전체', '자유게시판', '문의사항'];

  Set<String> _selectedPostIds = {};
  bool _isSelectionMode = false;

  // ========== 초기화 ==========
  @override
  void initState() {
    super.initState();
    _loadMyPosts();
  }

  // ========== 데이터 로드 ==========
  Future<void> _loadMyPosts() async {
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
      final posts = await _postService.getMyPosts(
        userId: currentUser.uid,
        category: _selectedCategory == '전체' ? null : _selectedCategory,
      );

      setState(() {
        _myPosts = posts;
        _isLoading = false;
        _selectedPostIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      print('❌ 내 게시글 로딩 실패: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글을 불러오는데 실패했습니다')),
        );
      }
    }
  }

  // ========== 分类切换 ==========
  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadMyPosts();
  }

  // ========== 帖子操作 ==========
  void _handlePostDelete() {
    if (_isSelectionMode && _selectedPostIds.isNotEmpty) {
      _deleteSelectedPosts();
    } else if (_isSelectionMode && _selectedPostIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제할 게시글을 선택해주세요')),
      );
    } else {
      setState(() {
        _isSelectionMode = true;
      });
    }
  }

  Future<void> _deleteSelectedPosts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('게시글 삭제'),
        content: Text(
            '선택한 ${_selectedPostIds.length}개의 게시글을 삭제하시겠습니까?\n'
                '삭제된 게시글은 복구할 수 없습니다.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      int successCount = 0;

      for (var postId in _selectedPostIds) {
        final success = await _postService.deletePost(postId);
        if (success) {
          successCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$successCount개의 게시글이 삭제되었습니다')),
        );
        await _loadMyPosts();
      }
    } catch (e) {
      print('❌ 게시글 삭제 실패: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글 삭제에 실패했습니다')),
        );
      }
    }
  }

  // ========== 卡片操作 ==========
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
      ).then((_) => _loadMyPosts());
    }
  }

  Future<void> _handleEdit(Post post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostEditorScreen(existingPost: post),
      ),
    );

    if (result == true) {
      _loadMyPosts();
    }
  }

  Future<void> _handleDelete(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('게시글 삭제'),
        content: Text('이 게시글을 삭제하시겠습니까?\n삭제된 게시글은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final success = await _postService.deletePost(post.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('게시글이 삭제되었습니다')),
          );
          await _loadMyPosts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('게시글 삭제에 실패했습니다')),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('❌ 게시글 삭제 실패: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글 삭제에 실패했습니다')),
        );
      }
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
      // ✅ 修改：跳转到 HomeScreen 而不是直接跳转到 CommunityListScreen
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
        MaterialPageRoute(
          builder: (context) => const HomeScreen(initialIndex: 0),
        ),
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
    return Scaffold(
      appBar: CustomAppBar(appName: '내가 쓴 게시글'),
      drawer: CustomDrawer(),
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          // 分类标签栏 - 使用共享组件
          CategoryTabs(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategoryChanged: _onCategoryChanged,
          ),

          Divider(height: 1, color: Colors.grey[300]),

          // 帖子列表
          Expanded(child: _buildPostList()),
        ],
      ),
      bottomSheet: ListBottomActions(
        actionType: ListActionType.deletePost,  // 注意：这里是 deletePost
        isSelectionMode: _isSelectionMode,
        selectedCount: _selectedPostIds.length,
        onPrimaryAction: _handlePostDelete,
        onSecondaryAction: _handleSecondaryAction,
      ),
      bottomNavigationBar: CustomFooter(
        currentIndex: 2,
        onTap: _handleFooterTap,
      ),
    );
  }

  /// 帖子列表
  Widget _buildPostList() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_myPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.article_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                '작성한 게시글이 없습니다',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _myPosts.length,
      itemBuilder: (context, index) {
        final post = _myPosts[index];
        final isSelected = _selectedPostIds.contains(post.id);

        return PostListCard(
          post: post,
          actionType: PostCardActionType.myPost,  // 使用 myPost 类型
          isSelected: isSelected,
          isSelectionMode: _isSelectionMode,
          onTap: () => _handleCardTap(post),
          onEdit: () => _handleEdit(post),
          onDelete: () => _handleDelete(post),  // 添加删除回调
        );
      },
    );
  }
}