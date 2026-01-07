// ==================================================================================
// 1. my_post_list_screen.dart - 내가 쓴 게시글 화면
// ==================================================================================
// community/screens/my_post_list_screen.dart

// 관련 파일:
// 1. shared/category_tabs.dart: 카테고리 탭
// 2. shared/post_list_card.dart: 게시글 카드
// 3. shared/list_bottom_actions.dart: 하단 액션 바
// 4. services/post_service.dart: 게시글 데이터 처리

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Models
import '../models/post_model.dart';

// Services
import '../services/post_service.dart';

// Widgets
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
  /// =====================================================================================
  /// 변수 선언
  /// =====================================================================================
  /// 1. 서비스
  final PostService _postService = PostService();

  /// 2. 게시글 데이터
  List<Post> _myPosts = []; // 내 게시글 목록
  bool _isLoading = false; // 로딩 상태

  /// 3. 카테고리
  String _selectedCategory = '전체'; // 선택된 카테고리
  final List<String> _categories = ['전체', '자유게시판', '문의사항']; // 카테고리 목록

  /// 4. 선택 모드 (삭제용)
  Set<String> _selectedPostIds = {}; // 선택된 게시글 ID 세트
  bool _isSelectionMode = false; // 선택 모드 활성화 여부

  /// =====================================================================================
  /// 초기화
  /// =====================================================================================
  @override
  void initState() {
    super.initState();
    _loadMyPosts(); // 내 게시글 불러오기
  }

  /// =====================================================================================
  /// 데이터 로드
  /// =====================================================================================
  /// 내 게시글 불러오기
  Future<void> _loadMyPosts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    // 로그인 확인
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
        _selectedPostIds.clear(); // 선택 초기화
        _isSelectionMode = false; // 선택 모드 해제
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

  /// =====================================================================================
  /// 카테고리 처리
  /// =====================================================================================
  /// 카테고리 변경 시
  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadMyPosts(); // 선택된 카테고리로 다시 불러오기
  }

  /// =====================================================================================
  /// 게시글 삭제 처리
  /// =====================================================================================
  /// 삭제 버튼 클릭 시 처리
  /// 중요: 선택 모드가 아니면 선택 모드로 전환, 이미 선택 모드면 삭제 실행
  void _handlePostDelete() {
    if (_isSelectionMode && _selectedPostIds.isNotEmpty) {
      // 선택 모드 + 선택된 항목 있음 → 삭제 실행
      _deleteSelectedPosts();
    } else if (_isSelectionMode && _selectedPostIds.isEmpty) {
      // 선택 모드 + 선택된 항목 없음 → 경고 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제할 게시글을 선택해주세요')),
      );
    } else {
      // 일반 모드 → 선택 모드로 전환
      setState(() {
        _isSelectionMode = true;
      });
    }
  }

  /// 선택된 게시글들 삭제
  Future<void> _deleteSelectedPosts() async {
    // 삭제 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('게시글 삭제'),
        content: Text(
            '선택한 ${_selectedPostIds.length}개의 게시글을 삭제하시겠습니까?\n'
                '삭제된 게시글은 복구할 수 없습니다.'),
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

      // 선택된 게시글들 순차 삭제
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
        await _loadMyPosts(); // 목록 새로고침
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

  /// =====================================================================================
  /// 카드 액션 처리
  /// =====================================================================================
  /// 카드 클릭 시 처리
  /// 중요: 선택 모드일 때는 선택/해제, 일반 모드일 때는 상세 화면으로 이동
  void _handleCardTap(Post post) {
    if (_isSelectionMode) {
      // 선택 모드: 선택/해제 토글
      setState(() {
        if (_selectedPostIds.contains(post.id)) {
          _selectedPostIds.remove(post.id);
        } else {
          _selectedPostIds.add(post.id);
        }
      });
    } else {
      // 일반 모드: 상세 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(postId: post.id),
        ),
      ).then((_) => _loadMyPosts()); // 돌아올 때 목록 새로고침
    }
  }

  /// 게시글 수정
  Future<void> _handleEdit(Post post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostEditorScreen(existingPost: post),
      ),
    );

    if (result == true) {
      _loadMyPosts(); // 수정 후 목록 새로고침
    }
  }

  /// 개별 게시글 삭제
  Future<void> _handleDelete(Post post) async {
    // 삭제 확인 다이얼로그
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
      print('게시글 삭제 실패: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글 삭제에 실패했습니다')),
        );
      }
    }
  }

  /// =====================================================================================
  /// 하단 액션 처리
  /// =====================================================================================
  /// 하단바 보조 버튼 클릭 시 (취소/돌아가기)
  void _handleSecondaryAction() {
    if (_isSelectionMode) {
      // 선택 모드: 선택 모드 해제 및 선택 초기화
      setState(() {
        _isSelectionMode = false;
        _selectedPostIds.clear();
      });
    } else {
      // 일반 모드: 이전 화면으로 돌아가기
      Navigator.pop(context);
    }
  }

  /// =====================================================================================
  /// Footer 네비게이션 처리
  /// =====================================================================================
  /// 하단 네비게이션 바 탭 처리
  /// 중요: HomeScreen을 통해 이동해야 상태가 유지됨
  void _handleFooterTap(int index) {
    if (index == 2) {
      // 커뮤니티 탭 → HomeScreen의 2번 인덱스로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(initialIndex: 2),
        ),
      );
    } else if (index == 1) {
      // 냉장고 탭 → HomeScreen의 1번 인덱스로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(initialIndex: 1),
        ),
      );
    } else if (index == 0) {
      // 홈 탭 → HomeScreen의 0번 인덱스로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(initialIndex: 0),
        ),
      );
    } else {
      // 개발 중인 기능
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('해당 기능은 개발 중입니다')),
      );
    }
  }

  /// =====================================================================================
  /// UI 구현
  /// =====================================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(appName: '내가 쓴 게시글'),
      drawer: CustomDrawer(),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 카테고리 탭
          CategoryTabs(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategoryChanged: _onCategoryChanged,
          ),

          Divider(height: 1, color: Colors.grey[300]),

          // 게시글 목록
          Expanded(child: _buildPostList()),
        ],
      ),
      // 하단 액션바
      bottomSheet: ListBottomActions(
        actionType: ListActionType.deletePost, // 게시글 삭제 타입
        isSelectionMode: _isSelectionMode,
        selectedCount: _selectedPostIds.length,
        onPrimaryAction: _handlePostDelete,
        onSecondaryAction: _handleSecondaryAction,
      ),
    );
  }

  /// =====================================================================================
  /// 위젯
  /// =====================================================================================
  /// 게시글 목록
  Widget _buildPostList() {
    // 로딩 중
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 게시글이 없는 경우
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

    // 게시글 목록
    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 80), // 하단바 공간 확보
      itemCount: _myPosts.length,
      itemBuilder: (context, index) {
        final post = _myPosts[index];
        final isSelected = _selectedPostIds.contains(post.id);

        return PostListCard(
          post: post,
          actionType: PostCardActionType.myPost, // 내 게시글 타입
          isSelected: isSelected,
          isSelectionMode: _isSelectionMode,
          onTap: () => _handleCardTap(post),
          onEdit: () => _handleEdit(post),
          onDelete: () => _handleDelete(post),
        );
      },
    );
  }
}