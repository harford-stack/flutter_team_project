// community/screens/community_list_screen.dart

import 'package:flutter/material.dart';

// Models
import '../models/post_model.dart';

// Services
import '../services/post_service.dart';

// Widgets
import '../widgets/community_list/post_grid.dart';
import '../widgets/shared/category_tabs.dart';
import '../../common/app_colors.dart';
import '../../common/custom_appbar.dart';
import '../../common/custom_drawer.dart';
import '../../common/custom_footer.dart';

// Screens
import 'community_detail_screen.dart';
import 'post_editor_screen.dart';
import '../../auth/home_screen.dart';

class CommunityListScreen extends StatefulWidget {
  final bool showAppBarAndFooter;

  const CommunityListScreen({
    super.key,
    this.showAppBarAndFooter = false,
  });

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  // ========== 변수 선언 ==========
  final TextEditingController _searchController = TextEditingController();
  final PostService _postService = PostService();

  List<Post> _posts = [];
  String _selectedCategory = '전체';
  final List<String> _categories = ['전체', '자유게시판', '문의사항'];
  bool _isLoading = false;
  String _sortOrder = '최신순';

  // ========== 초기화 ==========
  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ========== 데이터 로드 ==========
  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    List<String> selectedCategories = [];
    if (_selectedCategory != '전체') {
      selectedCategories = [_selectedCategory];
    }

    final posts = await _postService.getPosts(
      searchQuery: _searchController.text,
      sortOrder: _sortOrder,
      categories: selectedCategories,
    );

    setState(() {
      _posts = posts;
      _isLoading = false;
    });
  }

  // ========== 导航 ==========
  Future<void> _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostEditorScreen(),
      ),
    );

    if (result == true) {
      await _loadPosts();
    }
  }

  void _handleFooterTap(int index) {
    if (index == 2) {
      return;
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
      backgroundColor: Colors.white,
      appBar: widget.showAppBarAndFooter ? CustomAppBar(appName: '커뮤니티') : null,
      drawer: widget.showAppBarAndFooter ? CustomDrawer() : null,
      body: Column(
        children: [
          // ✅ 第一行：搜索框（像小红书）
          _buildSearchBar(),

          // ✅ 第二行：分类标签 + 排序
          _buildCategoryAndSort(),

          // ✅ 帖子瀑布流
          PostGrid(
            isLoading: _isLoading,
            posts: _posts,
            onPostTap: (post) async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(postId: post.id),
                ),
              );
              _loadPosts();
            },
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: widget.showAppBarAndFooter ? 80 : 16,
        ),
        child: FloatingActionButton(
          onPressed: _navigateToCreatePost,
          backgroundColor: AppColors.primaryColor,
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: widget.showAppBarAndFooter
          ? CustomFooter(
        currentIndex: 2,
        onTap: _handleFooterTap,
      )
          : null,
    );
  }

  /// 搜索栏（简洁干净）
  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onSubmitted: (_) => _loadPosts(),
        decoration: InputDecoration(
          hintText: '게시글 제목이나 내용으로 검색',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// 分类标签 + 排序筛选（在同一行）
  Widget _buildCategoryAndSort() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          // 左边：分类标签
          Expanded(
            child: CategoryTabs(
              categories: _categories,
              selectedCategory: _selectedCategory,
              onCategoryChanged: (category) {
                setState(() => _selectedCategory = category);
                _loadPosts();
              },
            ),
          ),

          // 右边：排序筛选（小图标 + 文字）
          GestureDetector(
            onTap: () {
              setState(() {
                _sortOrder = _sortOrder == '최신순' ? '인기순' : '최신순';
              });
              _loadPosts();
            },
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 18, color: Colors.grey[700]),
                SizedBox(width: 4),
                Text(
                  _sortOrder,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
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