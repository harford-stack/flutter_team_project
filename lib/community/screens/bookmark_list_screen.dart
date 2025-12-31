import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../services/bookmark_service.dart';
import '../../auth/auth_provider.dart';
import '../../common/custom_appbar.dart';
import '../../common/custom_footer.dart';
import '../../common/custom_drawer.dart';
import '../../common/app_colors.dart';
import '../../common/bookmark_button.dart';
import 'community_detail_screen.dart';
import '../../recipes/ingreCheck_screen.dart';

/// ========================================
/// BookmarkListScreen - 북마크 관리 화면
/// ========================================
///
/// 页面功能：
/// 1. 显示当前用户收藏的所有帖子
/// 2. 支持按分类筛选（전체/자유게시판/문의사항）
/// 3. 支持批量取消书签（点击底部按钮进入选择模式）
/// 4. 点击卡片跳转到详情页
///
/// 页面结构：
/// - CustomAppBar（顶部导航栏）★ 复用
/// - 标题区域（"북마크 목록"）
/// - 分类Tab栏（3个按钮）
/// - 帖子列表（滚动区域）
/// - 底部操作栏（북마크 해제 + 돌아기기）
/// - CustomFooter（底部导航栏）★ 复用
///
/// 复用的Widget：
/// 1. CustomAppBar - 统一的顶部导航栏
/// 2. CustomFooter - 统一的底部导航栏
/// 3. CustomDrawer - 侧边抽屉菜单
/// 4. BookmarkButton - 你提供的书签按钮组件（重点复用！）
/// ========================================

class BookmarkListScreen extends StatefulWidget {
  const BookmarkListScreen({Key? key}) : super(key: key);

  @override
  State<BookmarkListScreen> createState() => _BookmarkListScreenState();
}

class _BookmarkListScreenState extends State<BookmarkListScreen> {

  /// ========================================
  /// 변수 선언 구역
  /// ========================================

  // ===== 서비스 =====
  final BookmarkService _bookmarkService = BookmarkService();

  // ===== 데이터 관련 =====
  List<Post> _bookmarkedPosts = [];      // 북마크한 post를 list에 추가
  bool _isLoading = false;                // 데이터를 로딩하고 있는지

  // ===== category관련 =====
  String _selectedCategory = '전체';      // 선택된 category
  final List<String> _categories = [     // 모든 선택가능한 category
    '전체',
    '자유게시판',
    '문의사항',
  ];

  // ===== 선택 모드 관련 =====
  /// _selectedPostIds: 선택된 post의 id를 저장
  /// - 使用 Set 而不是 List 的原因：自动去重，避免重复添加同一个ID
  /// - 用途：批量删除时传递给 BookmarkService
  Set<String> _selectedPostIds = {};

  /// _isSelectionMode: "선택 모드"에 처해 있는지--밑에 있는 "북마크 헤제" 버턴을 누르면
  /// - false（일반 모드）：BookmarkButton를 디스플래이하고，카드를 클릭하면 상세페이지로 간다.
  /// - true（선택 모드）：다선택 화면이 나타나고 카드를 클릭하고 선택 상태를 전환
  bool _isSelectionMode = false;

  /// ========================================
  /// 초기화
  /// ========================================
  @override
  void initState() {
    super.initState();
    // 页面加载时立即获取书签列表
    _loadBookmarkedPosts();
  }

  /// ========================================
  /// 핵심 함수 구역
  /// ========================================

  /// ===== 북마크 리스트를 로딩 =====
  ///
  /// 执行流程：
  /// 1. 从 AuthProvider 获取当前登录用户（参考 PostDetailScreen 的逻辑）
  /// 2. 如果未登录 → 提示"로그인이 필요합니다"
  /// 3. 调用 BookmarkService 获取数据
  /// 4. 更新界面状态
  /// 5. 重置选择模式
  Future<void> _loadBookmarkedPosts() async {
    // ===== step1: 해당 사용자를 가져오기=====
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    // ===== step2: 해당 사용자의 로그인 상태를 검정 =====
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    // ===== step3: 로딩상태 보여주기 =====
    setState(() => _isLoading = true);

    try {
      // ===== step4: 서비스층 데이터를 가져오기 =====
      final posts = await _bookmarkService.getBookmarkedPosts(
        currentUser.uid,
        category: _selectedCategory == '전체' ? null : _selectedCategory,
      );

      // ===== step5: 화면 갱신 =====
      //为什么不能写成只有等号前面的样子：因为 Dart 是“命令式语言”，不是“声明式监听语言”
      setState(() {
        _bookmarkedPosts = posts;
        _isLoading = false;
        _selectedPostIds.clear();       // 선택된 항목을 삭제
        _isSelectionMode = false;       // 선택 모드에서 나가기
      });
    } catch (e) {
      print('북마크 로딩 실패: $e');
      setState(() => _isLoading = false);


      // mounted 是 State 类自带的一个 bool 属性：
      // true：这个 State 还挂在 Widget 树上
      // false：这个页面已经被销毁了（比如你已经返回上一页）

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크를 불러오는데 실패했습니다')),
        );
      }
    }
  }

  /// ===== category를 전환 =====
  ///
  /// 参数：category - 用户点击的分类名称
  ///
  /// 执行流程：
  /// 1. 更新 _selectedCategory
  /// 2. 重新加载数据（会自动退出选择模式）
  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadBookmarkedPosts();
  }

  /// ===== 处理底部"북마크 해제"按钮点击 =====
  ///
  /// 三种状态：
  /// 1. 普通模式 → 进入选择模式
  /// 2. 选择模式但没选中 → 提示用户选择
  /// 3. 选择模式且有选中 → 执行批量删除
  void _handleBookmarkRemove() {
    if (_isSelectionMode && _selectedPostIds.isNotEmpty) {
      // 状态3：执行批量删除
      _removeSelectedBookmarks();
    } else if (_isSelectionMode && _selectedPostIds.isEmpty) {
      // 状态2：提示用户选择
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제할 항목을 선택해주세요')),
      );
    } else {
      // 状态1：进入选择模式
      setState(() {
        _isSelectionMode = true;
      });
    }
  }

  /// ===== 批量取消书签 =====
  ///
  /// 执行流程：
  /// 1. 弹出确认对话框
  /// 2. 调用服务层批量删除
  /// 3. 刷新列表
  Future<void> _removeSelectedBookmarks() async {
    // ===== 步骤1: 显示确认对话框 =====
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

    // ===== 步骤2: 获取当前用户 =====
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null) return;

    // ===== 步骤3: 显示加载状态 =====
    setState(() => _isLoading = true);

    try {
      // ===== 步骤4: 调用服务层批量删除 =====
      final successCount = await _bookmarkService.removeMultipleBookmarks(
        currentUser.uid,            // ← 改成这个顺序
        _selectedPostIds.toList(),
      );

      // ===== 步骤5: 显示成功提示并刷新列表 =====
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

  /// ===== Footer 导航处理（参考 PostDetailScreen 的逻辑）=====
  void _handleFooterTap(int index) {
    if (index == 2) {
      // 当前页面，不做处理
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => IngrecheckScreen()),
      );
    } else if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('해당 기능은 개발 중입니다')),
      );
    }
  }

  /// ========================================
  /// UI构建函数区域
  /// ========================================

  /// ===== 构建分类Tab栏 =====
  Widget _buildCategoryTabs() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;

          return Expanded(
            child: GestureDetector(
              onTap: () => _onCategoryChanged(category),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryColor : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// ===== 构建单个帖子卡片 =====
  ///
  /// 卡片布局：
  /// - 左侧：100x100 缩略图
  /// - 右侧：分类标签、标题、作者、互动数据
  /// - 右下角：根据模式显示 BookmarkButton 或复选框
  ///
  /// 交互逻辑：
  /// - 普通模式点击 → 跳转详情页
  /// - 选择模式点击 → 切换选中状态
  Widget _buildPostCard(Post post) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final isSelected = _selectedPostIds.contains(post.id);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          // 选择模式：切换选中状态
          setState(() {
            if (isSelected) {
              _selectedPostIds.remove(post.id);
            } else {
              _selectedPostIds.add(post.id);
            }
          });
        } else {
          // 普通模式：跳转详情页
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(postId: post.id),
            ),
          ).then((_) => _loadBookmarkedPosts());
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ===== 左侧：缩略图 =====
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: post.thumbnailUrl.isNotEmpty
                  ? Image.network(
                post.thumbnailUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                  );
                },
              )
                  : Container(
                width: 100,
                height: 100,
                color: Colors.grey[200],
              ),
            ),

            // ===== 右侧：信息区域 =====
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 分类标签
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        post.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),

                    // 标题
                    Text(
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),

                    // 作者昵称
                    Text(
                      post.nickName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),

                    // 底部信息栏
                    Row(
                      children: [
                        Text(
                          '댓글 ${post.commentCount}',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '북마크 ${post.bookmarkCount}',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Spacer(),

                        //============= 보통 모드 =================
                        // =====  复用 BookmarkButton（普通模式） =====
                        if (!_isSelectionMode && currentUser != null)
                          BookmarkButton(
                            isInitialBookmarked: true,
                            size: 20,
                            isTransparent: true,
                            onToggle: (isBookmarked) async {
                              if (!isBookmarked) {
                                await _bookmarkService.removeBookmark(
                                  currentUser.uid,  // ← userId 在前
                                  post.id,
                                );
                                _loadBookmarkedPosts();
                              }
                            },
                          ),

                        // ===== 复选框（选择模式）=====
                        if (_isSelectionMode)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                                : null,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ===== 构建帖子列表 =====
  Widget _buildPostList() {
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
        return _buildPostCard(_bookmarkedPosts[index]);
      },
    );
  }

  /// ===== 构建底部操作栏 =====
  ///
  /// 按钮状态：
  /// 1. 普通模式："북마크 해제" | "돌아기기"
  /// 2. 选择模式（未选中）："삭제할 항목 선택" | "취소"
  /// 3. 选择模式（已选中）："북마크 해제 (N)" | "취소"
  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ===== 左按钮：북마크 해제 =====
          Expanded(
            child: ElevatedButton(
              onPressed: _handleBookmarkRemove,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSelectionMode && _selectedPostIds.isNotEmpty
                    ? Colors.red
                    : AppColors.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isSelectionMode
                    ? _selectedPostIds.isEmpty
                    ? '삭제할 항목 선택'
                    : '북마크 해제 (${_selectedPostIds.length})'
                    : '북마크 해제',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),

          // ===== 右按钮：돌아기기 / 취소 =====
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (_isSelectionMode) {
                  // 选择模式：取消选择，退出选择模式
                  setState(() {
                    _isSelectionMode = false;
                    _selectedPostIds.clear();
                  });
                } else {
                  // 普通模式:돌아가기
                  Navigator.pop(context);
                }
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isSelectionMode ? '취소' : '돌아기기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ========================================
  /// 主构建函数 - 组装整个页面
  /// ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ===== ★ 复用：CustomAppBar =====
      appBar: CustomAppBar(),

      // ===== ★ 复用：CustomDrawer =====
      drawer: CustomDrawer(),

      backgroundColor: AppColors.backgroundColor,

      body: Column(
        children: [
          // 标题区域
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  '북마크 목록',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 分类Tab栏
          _buildCategoryTabs(),

          Divider(height: 1, color: Colors.grey[300]),

          // 帖子列表
          Expanded(child: _buildPostList()),
        ],
      ),

      // 底部操作栏
      bottomSheet: _buildBottomActions(),

      // ===== ★ 复用：CustomFooter =====
      bottomNavigationBar:CustomFooter(
          currentIndex: 2,
          onTap: _handleFooterTap,
        ),
    );
  }
}