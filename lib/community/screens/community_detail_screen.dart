// community/screens/community_detail_screen.dart

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

/// 帖子详情页
class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String? highlightCommentId;

  const PostDetailScreen({
    Key? key,
    required this.postId,
    this.highlightCommentId,
  }) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? _post;
  bool _isLoading = false;
  bool _isLoadingCo = false;
  bool _isInputExpanded = false;
  bool _isBookmarked = false;
  List<Comment> _comments = [];
  Comment? _replyingTo;

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _commentKeys = {};

  // ✅ 新增：记录哪些主评论是展开的
  final Set<String> _expandedCommentIds = {};

  final PostDetailService _detailService = PostDetailService();
  final CommentService _commentService = CommentService();
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _loadPostDetail();
    _loadComments();
    _checkBookmarkStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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

  Future<void> _loadComments() async {
    setState(() => _isLoadingCo = true);
    try {
      final comments = await _commentService.getComments(widget.postId);
      setState(() {
        _comments = comments;
        _isLoadingCo = false;
      });

      // ✅ 如果有高亮评论，自动展开包含它的主评论
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

  /// ✅ 新增：自动展开包含高亮评论的主评论
  void _autoExpandForHighlight(String commentId) {
    // 查找这个评论属于哪个主评论
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

    // 如果是回复，找到它的主评论
    if (targetComment.pComment != null) {
      String mainCommentId = _findMainCommentId(targetComment.pComment!);
      setState(() {
        _expandedCommentIds.add(mainCommentId);
      });
    } else {
      // 如果本身就是主评论，直接展开
      setState(() {
        _expandedCommentIds.add(commentId);
      });
    }
  }

  /// ✅ 新增：查找主评论ID（递归查找）
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

    // 如果有父评论，继续向上查找
    if (comment.pComment != null) {
      return _findMainCommentId(comment.pComment!);
    }

    // 已经是主评论
    return comment.id;
  }

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

      // ✅ 获取新评论ID
      final newCommentId = await _commentService.addComment(
        postId: widget.postId,
        userId: currentUser.uid,
        nickName: nickName,
        content: commentContent,
        pComment: parentCommentId,
      );

      if (newCommentId != null) {
        // 主评论通知
        if (parentCommentId == null && _post!.userId != currentUser.uid) {
          await _sendMainCommentNotification(
            postAuthorId: _post!.userId,
            postId: widget.postId,
            commentId: newCommentId,  // ✅ 新主评论ID
            fromUserId: currentUser.uid,
            fromNickName: nickName,
            commentContent: commentContent,
          );
        }
        // 回复通知
        else if (parentCommentId != null) {
          final parentComment = _comments.firstWhere((c) => c.id == parentCommentId);
          if (parentComment.userId != currentUser.uid) {
            await _sendReplyNotification(
              commentAuthorId: parentComment.userId,
              postId: widget.postId,
              commentId: newCommentId,  // ✅ 添加这个参数
              parentCommentId: parentCommentId,
              fromUserId: currentUser.uid,
              fromNickName: nickName,
              replyContent: commentContent,
            );
          }
        }

        _commentController.clear();
        setState(() {
          _replyingTo = null;
          _isInputExpanded = false;
        });
        _commentFocusNode.unfocus();
        await _loadComments();
        await _loadPostDetail();
      }
    } catch (e) {
      print('댓글 작성 실패: $e');
    }
  }

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

  void _handleExpandInput() {
    setState(() => _isInputExpanded = true);
    _commentFocusNode.requestFocus();
  }

  void _handleCancelInput() {
    setState(() {
      _replyingTo = null;
      _isInputExpanded = false;
      _commentController.clear();
    });
  }

  /// ✅ 新增：切换评论展开状态
  void _toggleCommentExpanded(String commentId) {
    setState(() {
      if (_expandedCommentIds.contains(commentId)) {
        _expandedCommentIds.remove(commentId);
      } else {
        _expandedCommentIds.add(commentId);
      }
    });
  }

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

  // ✅ 댓글通知：传入新评论的ID
  Future<void> _sendMainCommentNotification({
    required String postAuthorId,
    required String postId,
    required String commentId,  // ✅ 新主评论的ID
    required String fromUserId,
    required String fromNickName,
    required String commentContent,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        postId: postId,
        commentId: commentId,  // ✅ 新主评论ID（点击后高亮这条评论）
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

      print('✅ 댓글 알림 전송 성공: commentId=$commentId');
    } catch (e) {
      print('❌ 알림 전송 실패: $e');
    }
  }

// ✅ 대댓글통知：传入新回复的ID
  Future<void> _sendReplyNotification({
    required String commentAuthorId,
    required String postId,
    required String commentId,  // ✅ 新回复的ID（用于高亮）
    required String parentCommentId,  // 被回复的评论ID（用于逻辑）
    required String fromUserId,
    required String fromNickName,
    required String replyContent,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        postId: postId,
        commentId: commentId,  // ✅ 新回复ID（点击后高亮这条回复）
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

      print('✅ 대댓글 알림 전송 성공: commentId=$commentId (parentId=$parentCommentId)');
    } catch (e) {
      print('❌ 알림 전송 실패: $e');
    }
  }

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

    for (var reply in allReplies) {
      if (!_commentKeys.containsKey(reply.id)) {
        _commentKeys[reply.id] = GlobalKey();
      }
    }

    return allReplies;
  }

  // 在 community_detail_screen.dart 的 build 方法中修改

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    for (var comment in _comments.where((c) => c.pComment == null)) {
      if (!_commentKeys.containsKey(comment.id)) {
        _commentKeys[comment.id] = GlobalKey();
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      // ✅ 添加 AppBar（让返回按钮更清晰）
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
                String shareText = _post!.content;

                // 如果内容太长，截取前200字
                if (shareText.length > 200) {
                  shareText = shareText.substring(0, 200) + '...';
                }

                Share.share(shareText);
              };
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ✅ 删除原来的这两行：
              // SliverToBoxAdapter(
              //   child: SizedBox(height: MediaQuery.of(context).padding.top + 44),
              // ),

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
                    ),
                  ),
                ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: _isInputExpanded ? 150 : 80,
                ),
              ),
            ],
          ),

          // ✅ 删除原来的这段 Positioned 返回按钮：
          // Positioned(
          //   top: MediaQuery.of(context).padding.top,
          //   left: 0,
          //   child: Container(
          //     height: 44,
          //     padding: EdgeInsets.only(left: 8),
          //     child: IconButton(
          //       icon: Icon(Icons.arrow_back_ios, size: 20, color: Colors.black87),
          //       onPressed: () => Navigator.pop(context),
          //     ),
          //   ),
          // ),

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

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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

              if (!_isInputExpanded)
                IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isBookmarked ? AppColors.primaryColor : Colors.grey[600],
                    size: 24,
                  ),
                  onPressed: _toggleBookmark,
                ),

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