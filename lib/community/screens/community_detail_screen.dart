import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../services/post_detail_service.dart';
import '../services/comment_service.dart';
import '../services/post_service.dart';
import '../../common/custom_appbar.dart';
import '../models/comment_model.dart';
import '../../auth/auth_provider.dart';
import '../../common/custom_footer.dart';
import '../../common/custom_drawer.dart';
import '../../recipes/ingreCheck_screen.dart';
import 'post_editor_screen.dart';
import '../../common/app_colors.dart';
import '../screens/community_list_screen.dart';


// ========================================
// 전체 로직 개요 (整体逻辑大纲)
// ========================================
//
// 📌 이 파일에는 2개의 핵심 서비스가 포함되어 있습니다:
//
// ┌─────────────────────────────────────────────────────────────┐
// │ 1. CommentService - 댓글 관리 서비스                          │
// └─────────────────────────────────────────────────────────────┘
//
// 【데이터 구조】
// post/{postId}/comment/{commentId}
//   ├── postId: 게시글 ID
//   ├── userId: 작성자 ID
//   ├── nickName: 작성자 닉네임
//   ├── content: 댓글 내용
//   ├── cdate: 생성 날짜
//   ├── udate: 수정 날짜
//   ├── likeCount: 좋아요 수
//   └── pComment: 부모 댓글 ID (답글인 경우만, 주 댓글은 null)
//
// 【핵심 로직】
// ① 평면적 저장 구조 (扁平化存储)
//    - 모든 댓글(주 댓글 + 답글)을 같은 컬렉션에 저장
//    - pComment 필드로 구분:
//      • pComment = null → 주 댓글 (최상위 댓글)
//      • pComment = "commentId" → 답글 (부모 댓글 ID 저장)
//
// ② 프론트엔드에서 트리 구조 생성 (前端构建树形结构)
//    - 서비스: 모든 댓글을 시간순으로 반환
//    - UI: 재귀 알고리즘으로 주 댓글 아래 답글 트리 구성
//
// ③ 무한 깊이 중첩 지원 (支持无限层级嵌套)
//    - A → B → C → D... 형태의 다층 답글 가능
//    - _getAllRepliesForMainComment() 함수로 모든 하위 답글 추출
//
// 【알림 연동 시 고려사항】 ⚠️ 향후 개발자 참고
// - 댓글 작성 시: 게시글 작성자에게 알림
// - 답글 작성 시: 부모 댓글 작성자에게 알림
// - 필요한 정보: postId, userId, pComment, 작성자 정보
//
// ┌─────────────────────────────────────────────────────────────┐
// │ 2. PostDetailService - 게시글 상세 및 북마크 서비스            │
// └─────────────────────────────────────────────────────────────┘
//
// 【데이터 구조】
// users/{userId}/UserBookmark/{bookmarkId}
//   ├── postId: 게시글 ID
//   ├── category: 게시글 분류
//   ├── title: 게시글 제목
//   ├── nickName: 작성자 닉네임
//   ├── cdate: 북마크 날짜
//   └── thumbnailUrl: 썸네일 URL
//
// post/{postId}
//   └── bookmarkCount: 북마크 수 (FieldValue.increment로 관리)
//
// 【핵심 로직】
// ① 이중 데이터 구조 (双重数据结构)
//    - UserBookmark: 사용자별 북마크 리스트 저장
//    - Post.bookmarkCount: 게시글의 총 북마크 수 카운트
//
// ② 동기화 메커니즘 (同步机制)
//    - 북마크 추가 시:
//      • UserBookmark에 문서 추가
//      • Post.bookmarkCount +1
//    - 북마크 삭제 시:
//      • UserBookmark에서 문서 삭제
//      • Post.bookmarkCount -1
//
// ③ 중복 방지 (防止重复)
//    - 북마크 추가 전 where 쿼리로 기존 북마크 확인
//    - 이미 존재하면 추가하지 않음
//
// 【알림 연동 시 고려사항】 ⚠️ 향후 개발자 참고
// - 북마크 추가 시: 게시글 작성자에게 알림
// - 필요한 정보: postId, userId, 북마크한 사용자 정보
// - 북마크 해제는 알림 불필요
//
// ========================================

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({
    Key? key,
    required this.postId,
  }) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  /// ========== 变量声明区域 ==========
  Post? _post;
  bool _isLoading = false;
  bool _isLoadingCo = false;
  bool _isInputExpanded = false;
  bool _isBookmarked = false;
  List<Comment> _comments = [];
  Comment? _replyingTo;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  /// ========== 服务声明区域 ==========
  final PostDetailService _detailService = PostDetailService();
  final CommentService _commentService = CommentService();
  final PostService _postService = PostService();

  /// ========== 页面初始化区域 ==========
  @override
  void initState() {
    super.initState();
    _loadPostDetail();
    _loadComments();
    _checkBookmarkStatus();
  }

  /// ========== 函数声明区域 ==========

  /// 加载帖子详情
  Future<void> _loadPostDetail() async {
    setState(() => _isLoading = true);

    try {
      final post = await _detailService.getPostById(widget.postId);
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글을 불러오는데 실패했습니다')),
        );
      }
    }
  }

  /// 加载评论列表
  Future<void> _loadComments() async {
    setState(() => _isLoadingCo = true);

    try {
      final comments = await _commentService.getComments(widget.postId);
      setState(() {
        _comments = comments;
        _isLoadingCo = false;
      });
    } catch (e) {
      print('댓글 로딩 실패: $e');
      setState(() => _isLoadingCo = false);
    }
  }

  /// 检查当前用户是否已收藏此帖
  Future<void> _checkBookmarkStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null) return;

    try {
      final isBookmarked = await _detailService.isBookmarked(
          widget.postId, currentUser.uid);
      if (mounted) {
        setState(() => _isBookmarked = isBookmarked);
      }
    } catch (e) {
      print('북마크 상태 확인 실패: $e');
    }
  }

  /// 切换收藏状态
  Future<void> _toggleBookmark() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    try {
      setState(() => _isBookmarked = !_isBookmarked);

      await _detailService.toggleBookmark(
        widget.postId,
        currentUser.uid,
        _post!,         // ← 需要传入 post 对象！
        _isBookmarked,
      );

      await _loadPostDetail();
    } catch (e) {
      setState(() => _isBookmarked = !_isBookmarked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('북마크 처리 실패')),
      );
    }
  }

  Future<void> _editPost() async {
    if (_post == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostEditorScreen(existingPost: _post),
      ),
    );

    if (result == true) {
      await _loadPostDetail();
    }
  }

  Future<void> _deletePost() async {
    if (_post == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('게시글 삭제'),
        content: Text('정말로 이 게시글을 삭제하시겠습니까?\n삭제된 게시글은 복구할 수 없습니다.'),
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await _postService.deletePost(widget.postId);

      Navigator.pop(context);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('게시글이 삭제되었습니다')),
          );
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글 삭제에 실패했습니다')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      print('게시글 삭제 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다')),
      );
    }
  }

  /// 提交评论（支持主评论和回复）
  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 내용을 입력하세요')),
      );
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인이 필요합니다')),
        );
        return;
      }

      // 添加调试信息
      print('🔍 当前用户 UID: ${currentUser.uid}');
      print('🔍 authProvider.nickName: ${authProvider.nickName}');

      String nickName = authProvider.nickName ?? '익명';
      print('✅ 最终使用的 nickName: $nickName');

      final success = await _commentService.addComment(
        postId: widget.postId,
        userId: currentUser.uid,
        nickName: nickName,
        content: _commentController.text.trim(),
        pComment: _replyingTo?.id,
      );

      if (success) {
        _commentController.clear();
        setState(() {
          _replyingTo = null;
          _isInputExpanded = false;
        });
        _commentFocusNode.unfocus();
        await _loadComments();
        await _loadPostDetail();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('댓글이 작성되었습니다')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 작성에 실패했습니다')),
        );
      }
    } catch (e) {
      print('댓글 작성 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다')),
      );
    }
  }


  /// 获取主评论下的所有回复（包括多层嵌套）
  List<Comment> _getAllRepliesForMainComment(String mainCommentId) {
    List<Comment> allReplies = [];
    Set<String> processedIds = {mainCommentId};

    void findReplies(String commentId) {
      final directReplies = _comments.where((c) =>
      c.pComment == commentId && !processedIds.contains(c.id)
      ).toList();

      for (var reply in directReplies) {
        processedIds.add(reply.id);
        allReplies.add(reply);
        findReplies(reply.id);
      }
    }

    findReplies(mainCommentId);
    return allReplies;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  /// 点击评论进行回复
  void _replyToComment(Comment comment) {
    setState(() {
      _replyingTo = comment;
      _isInputExpanded = true;
    });

    _commentController.text = '@${comment.nickName} ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );

    _commentFocusNode.requestFocus();
  }

  void _handleFooterTap(int index) {
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CommunityListScreen()),
      );
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

  /// ========== UI构建区域 ==========
  Widget _buildAuthorSection() {
    if (_post == null) return SizedBox();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final isMyPost = currentUser != null && currentUser.uid == _post!.userId;

    return Container(
      decoration:BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _post!.nickName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          if (isMyPost) ...[
            IconButton(
              icon: Icon(Icons.edit, color:AppColors.primaryColor),
              onPressed: _editPost,
              tooltip: '수정',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: AppColors.primaryColor),
              onPressed: _deletePost,
              tooltip: '삭제',
            ),
          ],

          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? Colors.yellow[700] : Colors.grey,
            ),
            onPressed: _toggleBookmark,
          ),
        ],
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContentSection() {
    if (_post == null) return SizedBox();

    return Container(
      color:AppColors.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _post!.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  _post!.category,
                  style: TextStyle(fontSize: 8, color: Colors.grey),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            child: _post!.thumbnailUrl.isNotEmpty
                ? Image.network(
              _post!.thumbnailUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(Icons.broken_image,
                        size: 50, color: Colors.grey),
                  ),
                );
              },
            )
                : Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            child: Text(
              _post!.content,
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            child: Row(
              children: [
                Text(
                  _post!.cdate.toString().split(' ')[0],
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                SizedBox(width: 16),
                Text(
                  '댓글 ${_post!.commentCount}',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                SizedBox(width: 8),
                Text(
                  '북마크 ${_post!.bookmarkCount}',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: Colors.grey[200]),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            child: Text(
              "댓글",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
          _buildCommentsList(),
        ],
      ),
    );
  }

  /// 构建评论列表
  Widget _buildCommentsList() {
    if (_isLoadingCo) {
      return Center(child: CircularProgressIndicator());
    }

    if (_comments.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('아직 댓글이 없습니다', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final mainComments = _comments.where((c) => c.pComment == null).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: mainComments.length,
        itemBuilder: (context, index) {
          final mainComment = mainComments[index];
          final replies = _getAllRepliesForMainComment(mainComment.id);

          return _buildCommentItem(mainComment, replies);
        },
      ),
    );
  }

  /// 构建单个评论项
  Widget _buildCommentItem(Comment mainComment, List<Comment> replies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          onTap: () => _replyToComment(mainComment),
          leading: CircleAvatar(radius: 20),
          title: Text(mainComment.nickName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mainComment.content),
              SizedBox(height: 4),
              Text(
                mainComment.cdate.toString().split(' ')[0],
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
        if (replies.isNotEmpty)
          Container(
            margin: EdgeInsets.only(left: 56, right: 16, bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: replies.map((reply) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _replyToComment(reply),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(radius: 12),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reply.nickName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                reply.content,
                                style: TextStyle(fontSize: 13),
                              ),
                              Text(
                                reply.cdate.toString().split(' ')[0],
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        Divider(height: 1, thickness: 1, color: Colors.grey[100]),
      ],
    );
  }

  /// 构建评论输入框
  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: _isInputExpanded ? _buildExpandedInput() : _buildCollapsedInput(),
    );
  }

  /// 折叠状态的输入框
  Widget _buildCollapsedInput() {
    return InkWell(
      onTap: () {
        setState(() => _isInputExpanded = true);
        _commentFocusNode.requestFocus();
      },
      child: Row(
        children: [
          Icon(Icons.comment),
          SizedBox(width: 8),
          Text('댓글을 작성하세요...'),
        ],
      ),
    );
  }

  /// 展开状态的输入框
  Widget _buildExpandedInput() {
    return Column(
      children: [
        if (_replyingTo != null)
          Row(
            children: [
              Text('${_replyingTo!.nickName}님에게 답글'),
              Spacer(),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _replyingTo = null;
                    _isInputExpanded = false;
                    _commentController.clear();
                  });
                },
              ),
            ],
          ),
        Row(
          children: [
            Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  decoration: InputDecoration(
                    hintText: '댓글을 입력하세요...',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.primaryColor,
                        width: 2,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                )
            ),
            IconButton(
              icon: Icon(Icons.send,color:AppColors.primaryColor),
              onPressed: _submitComment,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      drawer: CustomDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color:AppColors.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: _buildAuthorSection(),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: _buildContentSection(),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
      bottomNavigationBar: CustomFooter(
        currentIndex: 2,
        onTap: _handleFooterTap,
      ),
    );
  }
}