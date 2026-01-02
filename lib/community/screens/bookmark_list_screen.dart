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
import '../screens/community_list_screen.dart';
import '../../auth/home_screen.dart';  // 添加这一行

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
  bool _isLoading = false;                // 데이터를 로딩하고 있는지=>로딩화면 나올 때 할 때 사용, 없어도 됨

  // ===== category관련 =====
  String _selectedCategory = '전체';      // 선택된 category
  final List<String> _categories = [     // 모든 선택가능한 category //叫category的list
    '전체',
    '자유게시판',
    '문의사항',
  ];

  // ===== 선택 모드 관련 =====
  ///선택 모드에서 선택된 post의 id
  Set<String> _selectedPostIds = {};

  /// _isSelectionMode: "선택 모드"에 처해 있는지--밑에 있는 "북마크 헤제" 버턴을 누르면
  /// - false（일반 모드）：1.BookmarkButton를 디스플래이하고(하난 씩 북마크 해제 가능)，2.카드를 클릭하면 상세페이지로 간다.
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
  //step 1:로그인 상태에서야만 북마크를 볼 수 있어서 로그인 상태를 확인
  Future<void> _loadBookmarkedPosts() async {
    // ===== step1: 해당 사용자를 가져오기=====
    //从 Provider 系统里，把 AuthProvider 这个“全局状态对象”拿出来
    //listen:false：不去实时监听，因为取用户信息是一次性的行为
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    //从 AuthProvider 里，取出当前登录用户
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
        //逻辑：假如选的是整体就可以不传关键词，假如没有选整体，传的就是关键词
        category: _selectedCategory == '전체' ? null : _selectedCategory,
      );

      // ===== step5: 화면 갱신 =====
      //为什么不能写成只有等号前面的样子：因为 Dart 是“命令式语言”，不是“声明式监听语言”
      setState(() {
        _bookmarkedPosts = posts;       // 서비스에서 꺼낸 값을 줌
        _isLoading = false;             // 로딩 화면 끔
        _selectedPostIds.clear();       // 선택된 항목을 삭제
        _isSelectionMode = false;       // 선택 모드에서 나가기
      });
    } catch (e) {
      print('북마크 로딩 실패: $e');
      setState(() => _isLoading = false);

      // 북마크 리스트 로딩 실패하고도 아직 이 페이지에 있다면 :'북마크를 불러오는데 실패했습니다'
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
  /// ===== ontap使得全局变量selectedCategory发生变化 =====
  void _onCategoryChanged(String category) {//底下tab栏上的分类被ontap时呼叫了这个函数，让全局变量_selectedCategory变成传入的category
    setState(() {
      _selectedCategory = category;
    });
    //북마크 리스트를 한번 더 꺼내오기
    _loadBookmarkedPosts();
  }

  /// ===== "북마크 해제"버턴을 클릭 =====
  void _handleBookmarkRemove() {
    if (_isSelectionMode && _selectedPostIds.isNotEmpty) {
      // 선택 모드에 처해 있으면서, 선택된게 있다=>handle하는 것은 멀티로 해제
      // 状态3：执行批量删除
      _removeSelectedBookmarks();
    } else if (_isSelectionMode && _selectedPostIds.isEmpty) {
      //선택 모드에 처해 있지는 않지만 선택된게 없다=>handle하는 것은 선택하라고 제시
      // 状态2：提示用户选择
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제할 항목을 선택해주세요')),
      );
    } else {
      //선택 모드가 아예 아닌 경우=>선택 모드를 켠다
      // 状态1：进入选择模式
      setState(() {
        _isSelectionMode = true;
      });
    }
  }

  /// ===== 멀티로 북마크 해제 =====
  Future<void> _removeSelectedBookmarks() async {
    // ===== step1 해제 확인  alertdialog=====
    //因为我们期望她以后不会再被赋值，所以用了final而不是bool
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
    //취소를 선택하면 그냥 돌아간다
    if (confirmed != true) return;

    // ===== step2: 로그인 상태를 확인=====
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    // 로그인 상태가 아니다면
    if (currentUser == null) return;

    // ===== 로드 상태 =====
    setState(() => _isLoading = true);

    try {
      // ===== step2: 사용자를 꺼내옴 =====
      final userId = Provider.of<AuthProvider>(context, listen: false).user!.uid;//是从auth_provider.dart里面取出来的
      // ===== step3: 서비스 측에서 멀티로 삭제 =====
      final successCount = await _bookmarkService.removeMultipleBookmarks(
        currentUser.uid,            // ← 改成这个顺序
        _selectedPostIds.toList(),
      );

      // ===== step4: 성공/실패했다고 제시 =====
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

  /// ===== Footer 네이비개이션 처리=====
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
  /// UI화면 구역
  /// ========================================

  /// ===== category Tab =====
  Widget _buildCategoryTabs() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //map：Dart 里遍历_categories列表并“转换”每个元素
        children: _categories.map((category) {
          //遍历的过程中，寻找选中的(_selectedCategory)和list里面的category相同就返回true，true的情况先就显示主题色，表示选中
          final isSelected = _selectedCategory == category;//返回true或者是false
          //这里expanded的目的：让每个分类按钮“等宽、铺满整行”
          return Expanded(
            child: GestureDetector(
              //_onCategoryChanged：让_selectedCategory附上值的方法
              onTap: () => _onCategoryChanged(category),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  //isSelected变成true/false的时候更换按钮和字体的颜色
                  color: isSelected ? AppColors.primaryColor : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
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

  /// ===== 북마크한 게시글네 카드 =====
  Widget _buildPostCard(Post post) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final isSelected = _selectedPostIds.contains(post.id);

    //(선택 모드)전역 변수 _selectedPostIds에 담긴 값을 처리+(일반 모드)의 상세 페이지로 이동의 로직
    //处理选择模式里全局变量_selectedPostIds里面的值+普通模式里的跳转
    return GestureDetector(
      onTap: () {
        //假如在选择模式：
        //如果已经选中了，再点击的时候就是remove
        //假如没有选中，再点击的时候就是add
        if (_isSelectionMode) {
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
            //这段是防止返回来的时候不能继续更新，而是返回的都是旧数据
          ).then((_) => _loadBookmarkedPosts());//Navigator.push(...) 返回的是：Future<T?>=>生命周期是当我们用pop返回的一刻，这里的 _ 表示不关心从详情页面返回的值
        }
      },

      // ==== 카드 양식 ====
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          //处理卡片在选择模式时的border变化：颜色和线的粗细
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
            // ===== 좌측:이미지 =====
            Padding(
              padding:EdgeInsets.all(16),
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
                    );
                  },
                )
                    : Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                ),
              ),
            ),

            // ===== 우측:정보 구역 =====
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // category 태그
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

                    // 작자 닉네임
                    Text(
                      post.nickName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),

                    // 밑에 있는 수치 정보란
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

                        //============= 보통 모드 (BookmarkButton)=================
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

                        //============= 선택 모드 (box)=================
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

  /// ===== 북마크 게시글 리시트 구현 =====
  //로딩할 때 나오는 화면
  Widget _buildPostList() {
    //로딩할 때
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    //리스트가 비어 있을 때
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

  /// ===== 밑에 있는 조작란 (주로 버튼 상태)=====
  ///
  /// 버튼 상태：
  /// 1. 일반 모드："북마크 해제" | "돌아기기"
  /// 2. 선택 모드（선택됨）："삭제할 항목 선택" | "취소"
  /// 3. 선택 모드（선택이 안됨）："북마크 해제 (N)" | "취소"
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
          // ===== 왼쪽 버튼：북마크 해제 =====
          Expanded(
            child: ElevatedButton(
              //_handleBookmarkRemove:모드전환+북마크해제 기능을 모두 처리하는 함수
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

          // ===== 오른쪽 버튼：돌아기기 / 취소 =====
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
  /// 총 ui 구현
  /// ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appName: '북마크 목록',
      ),

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
                // Text(
                //   '북마크 목록',
                //   style: TextStyle(
                //     fontSize: 20,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
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

      bottomNavigationBar:CustomFooter(
        currentIndex: 2,
        onTap: _handleFooterTap,
      ),
    );
  }
}