// 커뮤니티 목록 화면 - 게시글들을 그리드 형태로 보여주는 메인 화면
// community/screens/community_list_screen.dart

//관련 파일:
//1. shared/category_tabs.dart: 위쪽 category tabs
//2. community_list/post_grid.dart: 카드
//3. community_list/search_section.dart는 잠시 폐지

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
import '../../ingredients/user_refrigerator.dart';

///할 일:
//1.try-catch를 _loadPosts에다 추가



class CommunityListScreen extends StatefulWidget {
  final bool showAppBarAndFooter; // 앱바와 하단바 표시 여부

  const CommunityListScreen({
    super.key,
    this.showAppBarAndFooter = false,
  });

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  ///=====================================================================================
  /// 변수 선언
  ///======================================================================================
  ///1.검색어 입력 controller
  final TextEditingController _searchController = TextEditingController();
  ///2. 서비스: 게시글 데이터를 가져오는
  final PostService _postService = PostService();
  ///3. 게시글 리스트
  List<Post> _posts = [];
  ///4. category
  String _selectedCategory = '전체'; // 현재 선택된 카테고리
  final List<String> _categories = ['전체', '자유게시판', '문의사항']; // 사용 가능한 카테고리 목록
  ///5. 로딩
  bool _isLoading = false; // 데이터 로딩 중인지
  ///6. 정열순
  String _sortOrder = '최신순'; // 정렬 순서 (최신순/인기순)

  /// =====================================================================================
  /// 초기화
  ///======================================================================================
  @override
  void initState() {
    super.initState();
    _loadPosts(); // 화면 시작할 때 게시글 불러오기
  }

  @override
  void dispose() {
    _searchController.dispose(); // 메모리 누수 방지를 위해 컨트롤러 해제
    super.dispose();
  }

  /// =====================================================================================
  /// 데이터를 처리하는 함수 (게시글을 가져오는)
  /// ======================================================================================
  // 서버에서 게시글 데이터를 가져오는 함수
  Future<void> _loadPosts() async {
    setState(() => _isLoading = true); // 로딩 시작

    // 선택된 카테고리 설정 ('전체'가 아니면 해당 카테고리만)
    List<String> selectedCategories = [];
    if (_selectedCategory != '전체') {
      selectedCategories = [_selectedCategory];
    }

    // PostService를 통해 게시글 가져오기
    //await是"强制等待"，但只在当前函数内！其他地方可以继续干别的
    final posts = await _postService.getPosts(
      searchQuery: _searchController.text, // 검색어
      sortOrder: _sortOrder, // 정렬 순서
      categories: selectedCategories, // 카테고리 필터
    );
    // 抛出异常的时候，会直接跳出函数，所以下面的也就不会执行=>会导致一直loading=>try-catch：e时false，用snackbar显示错误
    setState(() {
      _posts = posts; // 가져온 게시글로 업데이트
      _isLoading = false; // 로딩 종료
    });
  }

  /// =====================================================================================
  /// navergation를 처리하는 함수들
  /// ======================================================================================
  /// 게시글 작성 화면으로 이동
  Future<void> _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostEditorScreen(),
      ),
    );

    // 게시글 작성 완료 후 돌아오면 목록 새로고침
    if (result == true) {
      await _loadPosts();
    }
  }

  // 하단 네비게이션 바 탭 처리
  void _handleFooterTap(int index) {
    if (index == 2) {
      return; // 현재 화면(커뮤니티)이므로 아무것도 안 함
    } else if (index == 1) {
      // 두 번째 탭 - 내 냉장고 화면으로 직접 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const UserRefrigerator(),
        ),
      );
    } else if (index == 0) {
      // 첫 번째 탭 - 홈 화면의 0번 인덱스로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(initialIndex: 0),
        ),
      );
    } else {
      // 아직 개발 중인 기능
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('해당 기능은 개발 중입니다')),
      );
    }
  }

  /// =====================================================================================
  /// UI 구현
  /// ======================================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.showAppBarAndFooter ? CustomAppBar(appName: '커뮤니티') : null,
      drawer: widget.showAppBarAndFooter ? CustomDrawer() : null,
      body: Column(
        children: [
          // 1. 검색란
          _buildSearchBar(),

          // 2. category tabs + 정렬 순서
          _buildCategoryAndSort(), // 카테고리 탭 + 정렬 버튼

          // 3.게시글 메이슨리 레이아웃
          PostGrid(
            isLoading: _isLoading,
            posts: _posts,
            onPostTap: (post) async {
              // 게시글 클릭 시 상세 화면으로 이동
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(postId: post.id),
                    ),
                  );
              _loadPosts(); // 돌아온 후 목록 새로고침
            },
          ),
        ],
      ),
      // 게시글 작성 버튼 (화면 하단 중앙에 떠있는 버튼)
      floatingActionButton: widget.showAppBarAndFooter
          ? Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom -20,
              ),
              child: FloatingActionButton(
                onPressed: _navigateToCreatePost, // 클릭 시 작성 화면으로
                backgroundColor: AppColors.primaryColor,
                child: Icon(Icons.add, color: Colors.white),
              ),
            )
          : FloatingActionButton(
              onPressed: _navigateToCreatePost, // 클릭 시 작성 화면으로
              backgroundColor: AppColors.primaryColor,
              child: Icon(Icons.add, color: Colors.white),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: widget.showAppBarAndFooter
          ? CustomFooter(
        currentIndex: 2, // 현재 탭 인덱스 (커뮤니티)
        onTap: _handleFooterTap,
      )
          : null,
    );
  }

  /// =====================================================================================
  /// widgets
  /// ======================================================================================
  /// 1. 검색창
  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        //onSubmitted：用户按键盘上的"完成"/"回车"键时会被触发
        onSubmitted: (_) => _loadPosts(), // 엔터 누르면 검색 실행
        decoration: InputDecoration(
          hintText: '게시글 제목이나 내용으로 검색', // 힌트 텍스트
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]), // search icon
          filled: true,
          fillColor: Colors.grey[100], // 연한 회색 배경
          contentPadding: EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20), // 둥근 모서리
            borderSide: BorderSide.none, // 테두리 없음
          ),
          //enabledBorder：text未被选中时候的border
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          //选中的时候的border（避免自动加默认的蓝色边框）
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }


  /// 2. category tabd & 정렬 버튼
  Widget _buildCategoryAndSort() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          // 왼쪽: 카테고리 탭들(import:shared/category_tabs)
          Expanded(
            //按照constructor传值
            child: CategoryTabs(
              categories: _categories,
              selectedCategory: _selectedCategory,
              //category tabs에서 클릭할 때 나오는 함수
              onCategoryChanged: (category) {
                setState(() => _selectedCategory = category); // 카테고리 변경
                _loadPosts(); // 변경된 카테고리로 게시글 다시 불러오기
              },
            ),
          ),

          // 오른쪽: 정렬 버튼 (아이콘 + 텍스트)
          GestureDetector(
            onTap: () {
              // 클릭할 때마다 최신순 ↔ 인기순 토글
              setState(() {
                _sortOrder = _sortOrder == '최신순' ? '인기순' : '최신순';
              });
              _loadPosts(); // 변경된 정렬로 게시글 다시 불러오기
            },
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 18, color: Colors.grey[700]), // 필터 아이콘
                SizedBox(width: 4),
                Text(
                  _sortOrder, // 현재 정렬 순서 표시
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