// 커뮤니티 상세 화면 - 게시글 내용과 댓글을 보여주는 화면
// community/screens/community_detail_screen.dart

// 관련 파일:
// 1. community_detail/content_section.dart: 게시글 내용 영역
// 2. community_detail/comment_list.dart: 댓글 목록 위젯
// 3. services/post_detail_service.dart: 게시글 상세 데이터 처리
// 4. services/comment_service.dart: 댓글 데이터 처리

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

// Models
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../../notifications/notification_model.dart';

// Services
import '../services/post_detail_service.dart';
import '../services/comment_service.dart';
import '../services/post_service.dart';

// Widgets
import '../widgets/community_detail/content_section.dart';
import '../widgets/community_detail/comment_list.dart';
import '../../common/app_colors.dart';

// Screens
import 'post_editor_screen.dart';
import '../../auth/auth_provider.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId; // 게시글 ID
  final String? highlightCommentId; // 하이라이트할 댓글 ID (알림에서 이동 시)

  const PostDetailScreen({
    Key? key,
    required this.postId,
    this.highlightCommentId,
  }) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  /// =====================================================================================
  /// 변수 선언
  /// =====================================================================================
  /// 1. 게시글 데이터
  Post? _post; // 현재 게시글 정보

  /// 2. 로딩 상태
  bool _isLoading = false; // 게시글 로딩 중인지
  bool _isLoadingCo = false; // 댓글 로딩 중인지

  /// 3. 입력 상태
  bool _isInputExpanded = false; // 댓글 입력창 확장 여부

  /// 4. 북마크 상태
  bool _isBookmarked = false; // 북마크 여부

  /// 5. 댓글 관련
  List<Comment> _comments = []; // 댓글 목록
  Comment? _replyingTo; // 답글 대상 댓글
  final Set<String> _expandedCommentIds = {}; // 확장된 댓글 ID 목록, set는 중복을 자동으로 제거하는 컬렉션 타입

  /// 6. 컨트롤러 및 키
  final TextEditingController _commentController = TextEditingController(); // 댓글 입력 컨트롤러
  final FocusNode _commentFocusNode = FocusNode(); // 댓글 입력 포커스
  final ScrollController _scrollController = ScrollController(); // 스크롤 컨트롤러
  final Map<String, GlobalKey> _commentKeys = {}; // 댓글별 키 (스크롤 이동용)

  /// 7. 서비스
  final PostDetailService _detailService = PostDetailService(); // 게시글 상세 서비스
  final CommentService _commentService = CommentService(); // 댓글 서비스
  final PostService _postService = PostService(); // 게시글 서비스

  /// =====================================================================================
  /// 초기화
  /// =====================================================================================
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _loadPostDetail(); // 게시글 정보 불러오기
    _loadComments(); // 댓글 불러오기
    _checkBookmarkStatus(); // 북마크 상태 확인
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// =====================================================================================
  /// 데이터를 처리하는 함수들 (게시글 및 댓글 로딩)
  /// =====================================================================================
  /// 게시글 상세 정보 불러오기
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

  /// 댓글 목록 불러오기
  Future<void> _loadComments() async {
    setState(() => _isLoadingCo = true);
    try {
      final comments = await _commentService.getComments(widget.postId);
      setState(() {
        _comments = comments;
        _isLoadingCo = false;
      });

      // 하이라이트할 댓글이 있으면 자동으로 해당 댓글이 포함된 주 댓글 확장(notification에서 올 때)
      if (widget.highlightCommentId != null) {
        _autoExpandForHighlight(widget.highlightCommentId!);
        await Future.delayed(Duration(milliseconds: 300));
        _scrollToComment(widget.highlightCommentId!);
      }
    } catch (e) {
      print('댓글 로딩 실패: $e');
      setState(() => _isLoadingCo = false);
    }
  }

  /// 북마크 상태 확인
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

  /// =====================================================================================
  /// 댓글 확장 및 스크롤 관련 함수들
  /// =====================================================================================
  /// 하이라이트할 댓글이 포함된 주 댓글 자동 확장
  void _autoExpandForHighlight(String commentId) {
    // 해당 댓글 찾기
    final targetComment = _comments.firstWhere(
          (c) => c.id == commentId,
      orElse: () => Comment(
        id: '',
        postId: '',
        userId: '',
        nickName: '',
        content: '',
        cdate: DateTime.now(),
      ),
    );

    if (targetComment.id.isEmpty) return;

    // 답글인 경우 주 댓글 찾기
    if (targetComment.pComment != null) {
      String mainCommentId = _findMainCommentId(targetComment.pComment!);
      setState(() {
        _expandedCommentIds.add(mainCommentId);
      });
    } else {
      // 주 댓글인 경우 바로 확장
      setState(() {
        _expandedCommentIds.add(commentId);
      });
    }
  }

  /// 주 댓글 ID 찾기 (재귀적으로 상위 댓글 탐색)
  String _findMainCommentId(String commentId) {
    final comment = _comments.firstWhere(
          (c) => c.id == commentId,
      orElse: () => Comment(
        id: '',
        postId: '',
        userId: '',
        nickName: '',
        content: '',
        cdate: DateTime.now(),
      ),
    );

    if (comment.id.isEmpty) return commentId;

    // 부모 댓글이 있으면 계속 상위로 탐색
    if (comment.pComment != null) {
      return _findMainCommentId(comment.pComment!);
    }

    // 주 댓글에 도달
    return comment.id;
  }

  /// 특정 댓글로 스크롤 이동
  void _scrollToComment(String commentId) {
    final key = _commentKeys[commentId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
        alignment: 0.1,
      );
    }
  }

  /// 댓글 확장/축소 토글
  void _toggleCommentExpanded(String commentId) {
    setState(() {
      if (_expandedCommentIds.contains(commentId)) {
        _expandedCommentIds.remove(commentId);
      } else {
        _expandedCommentIds.add(commentId);
      }
    });
  }

  /// 주 댓글의 모든 답글 가져오기 (재귀적)
  List<Comment> _getAllRepliesForMainComment(String mainCommentId) {
    List<Comment> allReplies = [];
    Set<String> processedIds = {mainCommentId};

    void findReplies(String commentId) {
      final directReplies = _comments
          .where((c) => c.pComment == commentId && !processedIds.contains(c.id))
          .toList();

      for (var reply in directReplies) {
        processedIds.add(reply.id);
        allReplies.add(reply);
        findReplies(reply.id);
      }
    }

    findReplies(mainCommentId);

    // 답글에 대한 키 생성
    for (var reply in allReplies) {
      if (!_commentKeys.containsKey(reply.id)) {
        _commentKeys[reply.id] = GlobalKey();
      }
    }

    return allReplies;
  }

  /// =====================================================================================
  /// 액션 처리 함수들 (북마크, 수정, 삭제, 댓글 작성)
  /// =====================================================================================
  /// 북마크 토글
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
      final wasNotBookmarked = !_isBookmarked;
      setState(() => _isBookmarked = !_isBookmarked);

      await _detailService.toggleBookmark(
        widget.postId,
        currentUser.uid,
        _post!,
        _isBookmarked,
      );

      // 북마크 알림 전송 (본인 게시글이 아닌 경우)
      if (wasNotBookmarked && _isBookmarked && _post!.userId != currentUser.uid) {
        await _sendBookmarkNotification(
          postAuthorId: _post!.userId,
          postId: widget.postId,
          fromUserId: currentUser.uid,
          fromNickName: authProvider.nickName ?? '사용자',
        );
      }

      await _loadPostDetail();
    } catch (e) {
      setState(() => _isBookmarked = !_isBookmarked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('북마크 처리 실패')),
      );
    }
  }

  /// 게시글 수정 화면으로 이동
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

  /// 게시글 삭제
  Future<void> _deletePost() async {
    if (_post == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('게시글 삭제'),
        content: Text('정말로 이 게시글을 삭제하시겠습니까?'),
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

    try {
      final success = await _postService.deletePost(widget.postId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글이 삭제되었습니다')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('게시글 삭제 오류: $e');
    }
  }

  /// 댓글 작성
  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인이 필요합니다')),
        );
        return;
      }

      String nickName = authProvider.nickName ?? '익명';
      String? parentCommentId = _replyingTo?.id;
      String commentContent = _commentController.text.trim();

      // 댓글 추가 및 새 댓글 ID 받기
      final newCommentId = await _commentService.addComment(
        postId: widget.postId,
        userId: currentUser.uid,
        nickName: nickName,
        content: commentContent,
        pComment: parentCommentId,
      );

      if (newCommentId != null) {
        // 주 댓글 알림 (본인 게시글이 아닌 경우)
        if (parentCommentId == null && _post!.userId != currentUser.uid) {
          await _sendMainCommentNotification(
            postAuthorId: _post!.userId,
            postId: widget.postId,
            commentId: newCommentId,
            fromUserId: currentUser.uid,
            fromNickName: nickName,
            commentContent: commentContent,
          );
        }
        // 답글 알림 (본인 댓글이 아닌 경우)
        else if (parentCommentId != null) {
          final parentComment = _comments.firstWhere((c) => c.id == parentCommentId);
          if (parentComment.userId != currentUser.uid) {
            await _sendReplyNotification(
              commentAuthorId: parentComment.userId,
              postId: widget.postId,
              commentId: newCommentId,
              parentCommentId: parentCommentId,
              fromUserId: currentUser.uid,
              fromNickName: nickName,
              replyContent: commentContent,
            );
          }
        }

        // 입력창 초기화
        _commentController.clear();
        setState(() {
          _replyingTo = null;
          _isInputExpanded = false;
        });
        _commentFocusNode.unfocus();

        // 데이터 새로고침
        await _loadComments();
        await _loadPostDetail();
      }
    } catch (e) {
      print('댓글 작성 실패: $e');
    }
  }

  /// 댓글에 답글 달기
  void _replyToComment(Comment comment) {
    if (!_commentKeys.containsKey(comment.id)) {
      _commentKeys[comment.id] = GlobalKey();
    }

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

  /// 댓글 입력창 확장
  void _handleExpandInput() {
    setState(() => _isInputExpanded = true);
    _commentFocusNode.requestFocus();
  }

  /// 댓글 입력 취소
  void _handleCancelInput() {
    setState(() {
      _replyingTo = null;
      _isInputExpanded = false;
      _commentController.clear();
    });
  }

  /// =====================================================================================
  /// 알림 전송 함수들
  /// =====================================================================================
  /// 북마크 알림 전송
  Future<void> _sendBookmarkNotification({
    required String postAuthorId,
    required String postId,
    required String fromUserId,
    required String fromNickName,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        postId: postId,
        commentId: null,
        fromUserId: fromUserId,
        fromNickName: fromNickName,
        type: NotificationType.bookmark,
        isRead: false,
        cdate: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(postAuthorId)
          .collection('notifications')
          .add(notification.toFirestore());
    } catch (e) {
      print('알림 전송 실패: $e');
    }
  }

  /// 댓글 알림 전송
  Future<void> _sendMainCommentNotification({
    required String postAuthorId,
    required String postId,
    required String commentId,
    required String fromUserId,
    required String fromNickName,
    required String commentContent,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        postId: postId,
        commentId: commentId,
        fromUserId: fromUserId,
        fromNickName: fromNickName,
        commentContent: commentContent,
        type: NotificationType.comment,
        isRead: false,
        cdate: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(postAuthorId)
          .collection('notifications')
          .add(notification.toFirestore());

      print('댓글 알림 전송 성공: commentId=$commentId');
    } catch (e) {
      print('알림 전송 실패: $e');
    }
  }

  /// 답글 알림 전송
  Future<void> _sendReplyNotification({
    required String commentAuthorId,
    required String postId,
    required String commentId,
    required String parentCommentId,
    required String fromUserId,
    required String fromNickName,
    required String replyContent,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        postId: postId,
        commentId: commentId,
        fromUserId: fromUserId,
        fromNickName: fromNickName,
        commentContent: replyContent,
        type: NotificationType.reply,
        isRead: false,
        cdate: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(commentAuthorId)
          .collection('notifications')
          .add(notification.toFirestore());

      print('대댓글 알림 전송 성공: commentId=$commentId (parentId=$parentCommentId)');
    } catch (e) {
      print('알림 전송 실패: $e');
    }
  }

  /// =====================================================================================
  /// UI 구현
  /// =====================================================================================
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    // 주 댓글에 대한 키 생성
    for (var comment in _comments.where((c) => c.pComment == null)) {
      if (!_commentKeys.containsKey(comment.id)) {
        _commentKeys[comment.id] = GlobalKey();
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      // 앱바 (뒤로가기, 공유 버튼)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.black87),
            onPressed: () {
              if (_post != null) {
                // 공유 내용 구성
                String shareText = '''
${_post!.title}

${_post!.content}

작성자: ${_post!.nickName}
카테고리: ${_post!.category}
날짜: ${_post!.cdate.toString().split(' ')[0]}
                '''.trim();

                Share.share(shareText);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // 로딩 중
          : Stack(
        children: [
          // 스크롤 가능한 콘텐츠
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 게시글 내용 및 댓글 목록
              if (_post != null)
                SliverToBoxAdapter(
                  child: PostContentSection(
                    post: _post!,
                    commentsWidget: CommentsList(
                      isLoading: _isLoadingCo,
                      comments: _comments,
                      highlightCommentId: widget.highlightCommentId,
                      commentKeys: _commentKeys,
                      expandedCommentIds: _expandedCommentIds,
                      onReplyToComment: _replyToComment,
                      onToggleExpanded: _toggleCommentExpanded,
                      getAllReplies: _getAllRepliesForMainComment,
                      postAuthorId: _post!.userId,
                    ),
                  ),
                ),

              // 하단 여백 (입력창 공간 확보)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _isInputExpanded ? 150 : 80,
                ),
              ),
            ],
          ),

          // 하단 고정 입력창
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomInputBar(),
          ),
        ],
      ),
    );
  }

  /// =====================================================================================
  /// 위젯
  /// =====================================================================================
  /// 하단 입력창
  Widget _buildBottomInputBar() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 답글 대상 표시 (확장된 경우)
          if (_isInputExpanded && _replyingTo != null)
            Row(
              children: [
                Text(
                  '${_replyingTo!.nickName}님에게 답글',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  onPressed: _handleCancelInput,
                ),
              ],
            ),

          // 입력창 및 버튼
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 댓글 입력 필드
              Expanded(
                child: GestureDetector(
                  onTap: _isInputExpanded ? null : _handleExpandInput,
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: 40,
                      maxHeight: _isInputExpanded ? 120 : 40,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _isInputExpanded
                        ? TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      maxLines: null,
                      style: TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '댓글을 입력하세요...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                        : Center(
                      child: Text(
                        '댓글을 작성하세요...',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),

              // 북마크 버튼 (입력창 축소 시)
              if (!_isInputExpanded)
                IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isBookmarked ? AppColors.primaryColor : Colors.grey[600],
                    size: 24,
                  ),
                  onPressed: _toggleBookmark,
                ),

              // 발송 버튼 (입력창 확장 시)
              if (_isInputExpanded)
                TextButton(
                  onPressed: _submitComment,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '발송',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}