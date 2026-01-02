import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../../auth/auth_provider.dart';
import '../../common/custom_appbar.dart';
import '../../common/custom_footer.dart';
import '../../common/custom_drawer.dart';
import '../../common/app_colors.dart';
import 'community_detail_screen.dart';
import 'post_editor_screen.dart';
import '../../recipes/ingreCheck_screen.dart';
import 'community_list_screen.dart';
import '../../auth/home_screen.dart';  // 添加这一行

/// ========================================
/// MyPostListScreen - 내가 쓴 게시글 목록 화면
/// ========================================

class MyPostListScreen extends StatefulWidget {
  const MyPostListScreen({Key? key}) : super(key: key);

  @override
  State<MyPostListScreen> createState() => _MyPostListScreenState();
}

class _MyPostListScreenState extends State<MyPostListScreen> {

  /// ========================================
  /// 변수 선언 구역
  /// ========================================

  // ===== 서비스 =====
  final PostService _postService = PostService();

  // ===== 데이터 관련 =====
  List<Post> _myPosts = [];              // 내가 쓴 게시글 리스트
  bool _isLoading = false;                // 로딩 상태

  // ===== category 관련 =====
  String _selectedCategory = '전체';      // 선택된 카테고리
  final List<String> _categories = [     // 모든 선택 가능한 카테고리
    '전체',
    '자유게시판',
    '문의사항',
  ];

  // ===== 선택 모드 관련 =====
  /// _selectedPostIds: 선택된 게시글 ID 저장
  /// - Set 사용 이유: 자동 중복 제거
  /// - 용도: 배치 삭제 시 PostService에 전달
  Set<String> _selectedPostIds = {};

  /// _isSelectionMode: 선택 모드 상태
  /// - false (일반 모드): 카드 클릭 시 상세페이지 이동
  /// - true (선택 모드): 카드 클릭 시 선택 상태 토글
  bool _isSelectionMode = false;

  /// ========================================
  /// 초기화
  /// ========================================
  @override
  void initState() {
    super.initState();
    // 페이지 로드 시 내 게시글 목록 가져오기
    _loadMyPosts();
  }

  /// ========================================
  /// 핵심 함수 구역
  /// ========================================

  /// ===== 내가 쓴 게시글 목록 로딩 =====

  Future<void> _loadMyPosts() async {
    // ===== step1: 현재 사용자 가져오기 =====
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    // ===== step2: 로그인 상태 확인 =====
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    // ===== step3: 로딩 상태 표시 =====
    setState(() => _isLoading = true);

    try {
      // ===== step4: 서비스층에서 데이터 가져오기 =====
      // ⚠️ 핵심: post 컬렉션에서 userId 필터링
      final posts = await _postService.getMyPosts(
        userId: currentUser.uid,
        category: _selectedCategory == '전체' ? null : _selectedCategory,
      );

      // ===== step5: 화면 갱신 =====
      setState(() {
        _myPosts = posts;
        _isLoading = false;
        _selectedPostIds.clear();       // 선택 항목 초기화
        _isSelectionMode = false;       // 선택 모드 해제
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

  /// ===== 카테고리 전환 =====
  ///
  /// 파라미터: category - 사용자가 클릭한 카테고리명
  ///
  /// 실행 흐름:
  /// 1. _selectedCategory 업데이트
  /// 2. 게시글 목록 다시 로드 (자동으로 선택 모드 해제됨)
  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadMyPosts();
  }

  /// ===== 하단 "게시글 삭제" 버튼 처리 =====
  ///
  /// 세 가지 상태 처리:
  /// 1. 일반 모드 → 선택 모드 진입
  /// 2. 선택 모드 + 선택 없음 → 선택하라는 안내
  /// 3. 선택 모드 + 선택 있음 → 배치 삭제 실행
  void _handlePostDelete() {
    if (_isSelectionMode && _selectedPostIds.isNotEmpty) {
      // 상태3: 배치 삭제 실행
      _deleteSelectedPosts();
    } else if (_isSelectionMode && _selectedPostIds.isEmpty) {
      // 상태2: 선택 안내
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제할 게시글을 선택해주세요')),
      );
    } else {
      // 상태1: 선택 모드 진입
      setState(() {
        _isSelectionMode = true;
      });
    }
  }

  /// ===== 선택한 게시글 배치 삭제 =====
  ///
  /// 실행 흐름:
  /// 1. 확인 다이얼로그 표시
  /// 2. 각 게시글에 대해 deletePost() 호출
  /// 3. PostService.deletePost()가 처리하는 것:
  ///    - 게시글 문서 삭제
  ///    - 썸네일 이미지 삭제
  ///    - post/{postId}/comment 서브컬렉션 전체 삭제
  ///    - users/{*}/UserBookmark에서 해당 postId 검색 후 삭제
  /// 4. 성공 메시지 표시 및 목록 새로고침
  Future<void> _deleteSelectedPosts() async {
    // ===== 단계1: 확인 다이얼로그 =====
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

    // ===== 단계2: 로딩 상태 표시 =====
    setState(() => _isLoading = true);

    try {
      int successCount = 0;

      // ===== 단계3: 각 게시글 삭제 =====
      for (var postId in _selectedPostIds) {
        final success = await _postService.deletePost(postId);
        if (success) {
          successCount++;
        }
      }

      // ===== 단계4: 성공 메시지 및 새로고침 =====
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$successCount개의 게시글이 삭제되었습니다')
          ),
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

  /// ===== Footer 네비게이션 처리 =====
  /// ===== Footer 导航处理（参考 PostDetailScreen 的逻辑）=====
  void _handleFooterTap(int index) {
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityListScreen(
            showAppBarAndFooter: true, // ✅ 传 true，显示完整的 AppBar 和 Footer
          ),
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => IngrecheckScreen()),
      );
    } else if (index == 0) {
      // ✅ 修改这里：使用 HomeScreen 类
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('해당 기능은 개발 중입니다')),
      );
    }
  }

  /// ========================================
  /// UI 구성 함수 구역
  /// ========================================

  /// ===== 카테고리 탭 바 구성 =====
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
                  color: isSelected
                      ? AppColors.primaryColor
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
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

  /// ===== 단일 게시글 카드 구성 =====
  ///
  /// 카드 레이아웃:
  /// - 왼쪽: 100x100 썸네일
  /// - 오른쪽: 카테고리 태그, 제목, 작성자, 통계 정보
  /// - 우하단: 모드에 따라 편집 버튼 또는 체크박스
  ///
  /// 인터랙션:
  /// - 일반 모드 클릭 → 상세페이지 이동
  /// - 선택 모드 클릭 → 선택 상태 토글
  Widget _buildPostCard(Post post) {
    final isSelected = _selectedPostIds.contains(post.id);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          // 선택 모드: 선택 상태 토글
          setState(() {
            if (isSelected) {
              _selectedPostIds.remove(post.id);
            } else {
              _selectedPostIds.add(post.id);
            }
          });
        } else {
          // 일반 모드: 상세페이지 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(postId: post.id),
            ),
          ).then((_) => _loadMyPosts()); // 돌아올 때 새로고침
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : Colors.grey[300]!,
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
            // ===== 왼쪽: 썸네일 =====
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
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
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                )
                    : Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                  child: Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              ),
            ),

            // ===== 오른쪽: 정보 영역 =====
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 카테고리 태그
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

                    // 제목
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

                    // 작성일
                    Text(
                      post.cdate.toString().split(' ')[0],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),

                    // 하단 정보 바
                    Row(
                      children: [
                        Icon(Icons.comment, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          '${post.commentCount}',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${post.bookmarkCount}',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Spacer(),

                        // ===== 일반 모드: 수정 버튼 =====
                        if (!_isSelectionMode)
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              size: 20,
                              color: AppColors.primaryColor,
                            ),
                            onPressed: () async {
                              // 수정 페이지로 이동
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostEditorScreen(
                                    existingPost: post, // 기존 게시글 전달
                                  ),
                                ),
                              );

                              // 수정 완료 후 목록 새로고침
                              if (result == true) {
                                _loadMyPosts();
                              }
                            },
                            tooltip: '수정',
                          ),

                        // ===== 선택 모드: 체크박스 =====
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

  /// ===== 게시글 목록 구성 =====
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
        return _buildPostCard(_myPosts[index]);
      },
    );
  }

  /// ===== 하단 작업 바 구성 =====
  ///
  /// 버튼 상태:
  /// 1. 일반 모드: "게시글 삭제" | "돌아가기"
  /// 2. 선택 모드 (미선택): "삭제할 게시글 선택" | "취소"
  /// 3. 선택 모드 (선택됨): "게시글 삭제 (N)" | "취소"
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
          // ===== 왼쪽 버튼: 게시글 삭제 =====
          Expanded(
            child: ElevatedButton(
              onPressed: _handlePostDelete,
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
                    ? '삭제할 게시글 선택'
                    : '게시글 삭제 (${_selectedPostIds.length})'
                    : '게시글 삭제',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),

          // ===== 오른쪽 버튼: 돌아가기 / 취소 =====
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (_isSelectionMode) {
                  // 선택 모드: 선택 취소 및 모드 해제
                  setState(() {
                    _isSelectionMode = false;
                    _selectedPostIds.clear();
                  });
                } else {
                  // 일반 모드: 이전 페이지로 돌아가기
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
                _isSelectionMode ? '취소' : '돌아가기',
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
  /// 메인 빌드 함수 - 전체 페이지 조립
  /// ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ===== ★ 재사용: CustomAppBar =====
      appBar: CustomAppBar(
        appName: '내가 쓴 게시글',
      ),

      // ===== ★ 재사용: CustomDrawer =====
      drawer: CustomDrawer(),

      backgroundColor: AppColors.backgroundColor,

      body: Column(
        children: [
          // // 제목 영역
          // Container(
          //   padding: EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //     boxShadow: [
          //       BoxShadow(
          //         color: Colors.black.withOpacity(0.1),
          //         blurRadius: 12,
          //         offset: Offset(0, 4),
          //       ),
          //     ],
          //   ),
          //   child: Row(
          //     children: [
          //       Icon(
          //         Icons.article,
          //         color: AppColors.primaryColor,
          //         size: 24,
          //       ),
          //       SizedBox(width: 12),
          //       Text(
          //         '내가 쓴 게시글',
          //         style: TextStyle(
          //           fontSize: 20,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          // 카테고리 탭 바
          _buildCategoryTabs(),

          Divider(height: 1, color: Colors.grey[300]),

          // 게시글 목록
          Expanded(child: _buildPostList()),
        ],
      ),

      // 하단 작업 바
      bottomSheet: _buildBottomActions(),

      // ===== ★ 재사용: CustomFooter =====
      bottomNavigationBar: CustomFooter(
        currentIndex: 2,
        onTap: _handleFooterTap,
      ),
    );
  }
}