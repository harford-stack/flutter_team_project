import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../services/post_detail_service.dart';
import '../services/comment_service.dart';
import '../../common/custom_appbar.dart';
import '../models/comment_model.dart';
import '../../auth/auth_provider.dart';

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
  ///변수 선언 구역
  Post? _post;
  bool _isLoading = false;
  bool _isLoadingCo = false;
  bool _isInputExpanded = false;
  List<Comment> _comments = [];
  Comment? _replyingTo;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  ///서비스 선언 구역
  final PostDetailService _detailService = PostDetailService();
  final CommentService _commentService = CommentService();

  ///페이지 초기화 구역
  @override
  void initState() {
    super.initState();
    _loadPostDetail();
    _loadComments();
  }

  ///함수 선언 구역
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글을 불러오는데 실패했습니다')),
      );
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
    } catch (e) {
      print('댓글 로딩 실패: $e');
      setState(() => _isLoadingCo = false);
    }
  }

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

      String nickName = currentUser.displayName ?? '익명';

      final success = await _commentService.addComment(
        postId: widget.postId,
        userId: currentUser.uid,
        nickName: nickName,
        content: _commentController.text.trim(),
      );

      if (success) {
        _commentController.clear();
        setState(() {
          _replyingTo = null;
          _isInputExpanded = false;
        });
        _commentFocusNode.unfocus();
        await _loadComments();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글이 작성되었습니다')),
        );
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

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

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

  Widget _buildAuthorSection() {
    if (_post == null) return SizedBox();

    return Container(
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
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    if (_post == null) return SizedBox();

    return Column(
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
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
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
          child: Text(
            _post!.cdate.toString().split(' ')[0],
            style: TextStyle(fontSize: 10, color: Colors.grey),
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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          child: ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return ListTile(
                onTap: () => _replyToComment(comment),
                title: Text(comment.nickName),
                leading: CircleAvatar(radius: 20),
                subtitle: Text(comment.content),
              );
            },
          ),
        ),
      ],
    );
  }

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
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: '댓글을 입력하세요...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            height: 100,
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
      bottomNavigationBar: BottomAppBar(),
    );
  }
}