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
import '../../auth/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../notifications/notification_model.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String? highlightCommentId; // ✅ 新增:要高亮的评论ID

  const PostDetailScreen({
    Key? key,
    required this.postId,
    this.highlightCommentId, // ✅ 可选参数
  }) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  /// ========== 변수 선언 구역 ==========
  Post? _post;
  bool _isLoading = false;//게시글이 로딩되고 있는지
  bool _isLoadingCo = false;//댓글이 로딩되고 있는지
  bool _isInputExpanded = false;//댓글 입력란이 열려 있는지
  bool _isBookmarked = false;
  List<Comment> _comments = [];
  Comment? _replyingTo;//회신할 때 누구를 향한 것인지
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();//입력란이 자동적으로 나옴+발송한 후 자기절로 돌아가게+남의 댓글을 크릭 시 입력란에 focus하게

  // ✅ 添加这两个缺失的变量
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _commentKeys = {};

  /// ========== 서비스 선언 구역 ==========
  final PostDetailService _detailService = PostDetailService();
  final CommentService _commentService = CommentService();
  final PostService _postService = PostService();

  /// ========== 초기화 ==========
  @override
  void initState() {
    super.initState();
    _loadPostDetail();
    _loadComments();
    _checkBookmarkStatus();

    // ✅ 如果有要高亮的评论,等加载完成后滚动过去
    if (widget.highlightCommentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToComment(widget.highlightCommentId!);
      });
    }
  }

  // ✅ 滚动到指定评论
  void _scrollToComment(String commentId) {
    final key = _commentKeys[commentId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
        alignment: 0.1, // ✅ 显示在屏幕顶部10%的位置
      );
    } else {
      print('⚠️ 未找到评论 $commentId 的 GlobalKey');
    }
  }

  /// ========== 함수 선언 구역 ==========

  /// 게시글 상세 로드 함수
  Future<void> _loadPostDetail() async {
    //지금 로드 상태에 있는지(로딩 페이지는 있는게 좋음, 꼭 필요하다는 것은 아님)
    setState(() => _isLoading = true);

    //서비스측에서 게시글 상세 내용을 꺼냄
    try {
      final post = await _detailService.getPostById(widget.postId);
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      //로딩 실패하고도 아직 이 페이지에 있다면 :'게시글을 불러오는데 실패했습니다'
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글을 불러오는데 실패했습니다')),
        );
      }
    }
  }

  /// 댓글 로딩 함수
  Future<void> _loadComments() async {
    setState(() => _isLoadingCo = true);
    try {
      final comments = await _commentService.getComments(widget.postId);
      setState(() {
        _comments = comments;
        _isLoadingCo = false;
      });

      // ✅ 关键修改：评论加载完成后再滚动
      if (widget.highlightCommentId != null) {
        // 等待UI完全渲染
        await Future.delayed(Duration(milliseconds: 300));
        _scrollToComment(widget.highlightCommentId!);
      }
    } catch (e) {
      print('댓글 로딩 실패: $e');
      setState(() => _isLoadingCo = false);
    }
  }

  /// 사용자가 이 게시글을 북마크 했는지 체크
  Future<void> _checkBookmarkStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);//防止过期，最好留着
    final currentUser = authProvider.user;
    //假如是null 就停止后续的检查,否则会崩
    if (currentUser == null) return;

    try {
      final isBookmarked = await _detailService.isBookmarked(
          widget.postId, currentUser.uid);
      if (mounted) {
        setState(() => _isBookmarked = isBookmarked);//给全局变量_isBookmarked赋值
      }
    } catch (e) {
      print('북마크 상태 확인 실패: $e');
    }
  }

  /// 북마크 상태를 전환
  /// 알림: 북마크 없는 상태에서 북마크하면 게시글 작자에게 알림을 준다: "북마크를 받았다"
  /// 假如有时间：一定时间内都是同一个文章被收藏（非其他文章，非评论）就group到一起，点开就能展开drawer，查看谁收藏了
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
      // 保存之前的状态，用于判断是否是"从未收藏转收藏"
      final wasNotBookmarked = !_isBookmarked;

      setState(() => _isBookmarked = !_isBookmarked);

      await _detailService.toggleBookmark(
        widget.postId,
        currentUser.uid,
        _post!,
        _isBookmarked,
      );

      // "x북마크 → 북마크"의 상태에서만 알림을 줌
      if (wasNotBookmarked && _isBookmarked) {
        // 내가 자기자신한테 알림을 주는 것을 방지
        if (_post!.userId != currentUser.uid) {
          await _sendBookmarkNotification(
            postAuthorId: _post!.userId,
            postId: widget.postId,
            fromUserId: currentUser.uid,
            fromNickName: authProvider.nickName ?? '사용자',
          );
        }
      }

      await _loadPostDetail();
    } catch (e) {
      setState(() => _isBookmarked = !_isBookmarked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('북마크 처리 실패')),
      );
    }
  }

// 북마크 알림을 줌
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

      print('북마크 알림 전송 성공');
    } catch (e) {
      print('알림 전송 실패: $e');
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

  /// 댓글 제출
  Future<void> _submitComment() async {
    // 비어 있는지 검사
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 내용을 입력하세요')),
      );
      return;
    }

    try {
      // 로그인 사용자 정보 확인
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

      // 서비스 측 댓글 추가
      final success = await _commentService.addComment(
        postId: widget.postId,
        userId: currentUser.uid,
        nickName: nickName,
        content: _commentController.text.trim(),
        pComment: parentCommentId,
      );

      if (success) {
        // ✅ 주 댓글인 경우 → 게시글 작성자에게 알림
        if (parentCommentId == null) {
          // 자기 자신에게는 알림 보내지 않기
          if (_post!.userId != currentUser.uid) {
            await _sendMainCommentNotification(
              postAuthorId: _post!.userId,
              postId: widget.postId,
              fromUserId: currentUser.uid,
              fromNickName: nickName,
              commentContent: _commentController.text.trim(), // ✅ 添加这行
            );
          }
        }
        // ✅ 대댓글인 경우 → 원댓글 작성자에게 알림
        else {
          // 원댓글 찾기
          final parentComment = _comments.firstWhere(
                (c) => c.id == parentCommentId,
          );

          // 자기 자신에게는 알림 보내지 않기
          if (parentComment.userId != currentUser.uid) {
            await _sendReplyNotification(
              commentAuthorId: parentComment.userId,
              postId: widget.postId,
              parentCommentId: parentCommentId,
              fromUserId: currentUser.uid,
              fromNickName: nickName,
              replyContent: _commentController.text.trim(), // ✅ 添加这行
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

  Future<void> _sendMainCommentNotification({
    required String postAuthorId,
    required String postId,
    required String fromUserId,
    required String fromNickName,
    required String commentContent, // ✅ 新增参数
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        postId: postId,
        commentId: null,
        fromUserId: fromUserId,
        fromNickName: fromNickName,
        commentContent: commentContent, // ✅ 传入内容
        type: NotificationType.comment,
        isRead: false,
        cdate: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(postAuthorId)
          .collection('notifications')
          .add(notification.toFirestore());

      print('주 댓글 알림 전송 성공');
    } catch (e) {
      print('알림 전송 실패: $e');
    }
  }

// ✅ 回复通知
  Future<void> _sendReplyNotification({
    required String commentAuthorId,
    required String postId,
    required String parentCommentId,
    required String fromUserId,
    required String fromNickName,
    required String replyContent, // ✅ 新增参数
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        postId: postId,
        commentId: parentCommentId,
        fromUserId: fromUserId,
        fromNickName: fromNickName,
        commentContent: replyContent, // ✅ 传入内容
        type: NotificationType.reply,
        isRead: false,
        cdate: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(commentAuthorId)
          .collection('notifications')
          .add(notification.toFirestore());

      print('대댓글 알림 전송 성공');
    } catch (e) {
      print('알림 전송 실패: $e');
    }
  }


  /// 주 댓글아래의 모든 댓글을 가져온다.
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
    _scrollController.dispose();
    super.dispose();
  }

  /// 댓글을 클릭하여 reply
  void _replyToComment(Comment comment) {
    setState(() {
      _replyingTo = comment;
      _isInputExpanded = true;
    });

    _commentController.text = '@${comment.nickName} ';
    //设置初始光标的位置
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );

    //告诉 Flutter：“这个 TextField 现在是活跃输入目标”
    //没有它用户需要再点一下才能打字
    _commentFocusNode.requestFocus();
  }

  void _handleFooterTap(int index) {
    if (index == 2) {
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
        MaterialPageRoute(builder: (context) => const HomeScreen(initialIndex: 0)),
      );
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
  /// 构建单个评论项
  Widget _buildCommentItem(Comment mainComment, List<Comment> replies) {
    // ✅ 确保每个评论都有唯一的 key
    if (!_commentKeys.containsKey(mainComment.id)) {
      _commentKeys[mainComment.id] = GlobalKey();
    }

    // ✅ 判断是否需要高亮
    final isHighlighted = widget.highlightCommentId == mainComment.id;

    return Column(
      key: _commentKeys[mainComment.id],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isHighlighted
                ? Colors.grey[100]
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
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
                // ✅ 为回复也添加 key
                if (!_commentKeys.containsKey(reply.id)) {
                  _commentKeys[reply.id] = GlobalKey();
                }
                final isReplyHighlighted = widget.highlightCommentId == reply.id;

                return Padding(
                  key: _commentKeys[reply.id],
                  padding: EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      // ✅ 改成淡灰色
                      color: isReplyHighlighted
                          ? Colors.grey[200]  // 回复用稍微深一点的灰色
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.all(8),
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
              controller: _scrollController, // ✅ 添加 controller
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