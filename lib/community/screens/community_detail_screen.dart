import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_detail_service.dart';
import '../services/comment_service.dart';
import '../../common/custom_appbar.dart';
import '../models/comment_model.dart';
import '../../auth/auth_provider.dart';
import 'package:provider/provider.dart';

class PostDetailScreen extends StatefulWidget {

  final String postId;

  const PostDetailScreen ({//这是 PostDetailScreen 这个 Widget 的构造函数
    Key? key,//Key?:表示可以传key,也可以传null
    required this.postId,//创建这个页面时，必须传 postId
  }):super(key: key);


  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  ///변수 선언 구역=====================================
  Post? _post; //post의 데이터를 저장
  bool _isLoading = false;//post 로딩 상태
  bool _isLoadingCo=false;//댓글 로딩 상태
  bool _isBookmarked = false;// 북마크 상태
  bool _isInputExpanded = false;  // 输入框是否展开
  bool _showCommentInput = false;
  List <Comment> _comments = [];
  // 新增：回复相关变量
  Comment? _replyingTo;  // 这是一个变量，存储"正在回复的评论"
  final TextEditingController _commentController = TextEditingController();  // 输入框控制器
  final FocusNode _commentFocusNode = FocusNode();  // 焦点控制


  ///서비스 선언 구역=====================================
  final PostDetailService _detailService = PostDetailService();
  final CommentService _commentService = CommentService();

  ///페이지 초기화 구역=============================================
  @override
  void initState() {
    super.initState();
    _loadPostDetail();
    _loadComments();
  }


  ///함수 선언 구역======================================================
  //핵심: post의 상세를 로딩
  Future<void> _loadPostDetail() async {
    // 步骤1: 显示加载状态
    setState(() => _isLoading = true);

    try {
      // 步骤2: 调用 Service 获取帖子数据
      final post = await _detailService.getPostById(widget.postId);


      // 步骤3: 更新状态,触发页面重新构建
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      // 错误处理
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글을 불러오는데 실패했습니다')),
      );
    }
  }


  // 북마크할 때 함수
  // Future<void> _toggleBookmark() async {
  //   if (_post == null) return;
  //
  //   setState(() {
  //     _isBookmarked = !_isBookmarked;
  //   });
  //
  //   await _detailService.toggleBookmark(widget.postId, _isBookmarked);
  //
  //   // 重新加载以更新收藏数
  //   _loadPostDetail();
  // }


  //댓글란 로딩
  Future<void> _loadComments() async {
    setState(() => _isLoadingCo = true);

    try {
      // 调用 CommentService 获取评论列表
      final comments = await _commentService.getComments(widget.postId);

      // 更新状态
      setState(() {
        _comments = comments;
        _isLoadingCo = false;
      });
    } catch (e) {
      print('댓글 로딩 실패: $e');
      setState(() => _isLoadingCo = false);
    }
  }

  //댓글 추가
  //댓글 추가
  Future<void> _submitComment() async {
    // 检查输入是否为空
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 내용을 입력하세요')),
      );
      return;
    }

    try {
      // ✅ 从 AuthProvider 获取当前用户
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      // ✅ 检查用户是否登录
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인이 필요합니다')),
        );
        return;
      }

      // ✅ 获取用户的昵称（从 displayName 或 Firestore）
      String nickName = currentUser.displayName ?? '익명';

      // 如果你的昵称存储在 Firestore 中，需要先获取
      // 你可能需要添加一个方法到 AuthService 来获取昵称
      // nickName = await _authService.getUserNickname(currentUser.uid);

      // ✅ 调用 CommentService 添加评论
      final success = await _commentService.addComment(
        postId: widget.postId,
        userId: currentUser.uid,           // ← Firebase 用户的 UID
        nickName: nickName,                // ← 用户昵称
        content: _commentController.text.trim(),
      );

      if (success) {
        // 清空输入框
        _commentController.clear();

        // 取消回复状态，关闭输入框
        setState(() {
          _replyingTo = null;
          _isInputExpanded = false;  // 恢复折叠状态
        });

        // 收起键盘
        _commentFocusNode.unfocus();

        // 重新加载评论列表
        await _loadComments();

        // 显示成功提示
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


  ///dispose===================================================
  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  //댓글을 회신
  void _replyToComment(Comment comment) {

    setState(() {
      _showCommentInput = true;  // 显示输入框
      _replyingTo = comment;
    });

    //自动填入昵称
    _commentController.text='@${comment.nickName}';

    //让光标移动到最后
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );

    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${comment.nickName}에게'),
        duration: Duration(seconds: 1),
      ),
    );

    // 聚焦到输入框
    _commentFocusNode.requestFocus();
  }
  
  //작자 고정란
  Widget _buildAuthorSection() {
    return Container(
      padding: EdgeInsets.all(16),
        child: Row(
         children:[
           CircleAvatar(

           ),
           SizedBox(width:12),
           Expanded(
             child:Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Text(
                   _post!.nickName,
                   style:TextStyle(
                     fontWeight: FontWeight.bold,
                     fontSize: 16,
                   ),
                 ),
               ],
             )
           ),
          ]
        ),
    );
  }

  //내용란
  Widget _buildContentSection(){
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
        //제목+categoryname
        Padding(
          padding:EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _post!.title,
                style:TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
              SizedBox(width:16),
              Text(
                _post!.category,
                style:TextStyle(
                  fontSize: 8,
                  color: Colors.grey
                ),
              ),

            ],
          ),
        ),


        //이미지
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32,vertical:10),  // 左右边距
          child: ClipRRect(
            child: _post!.thumbnailUrl.isNotEmpty
                ? Image.network(
              _post!.thumbnailUrl,
              width: double.infinity,  // 占满宽度
              height: 200,  // 固定高度
              fit: BoxFit.cover,  // 裁剪适配
              // 加载中显示
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
              // 加载失败显示
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
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
                child: Icon(
                  Icons.image,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ),
        //본문
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32,vertical:10),
          child: Text(
            _post!.content,
            style:TextStyle(
                fontSize: 16,
                color: Colors.black
            ),

          )
        ),

        //날짜
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 32,vertical:10),
            child: Text(
              _post!.cdate.toString().split(' ')[0],
              style:TextStyle(
                fontSize: 10,
                color: Colors.grey
              ),

            )
        ),

        SizedBox(height:16),

        //중간에 분간하는 선
        Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey[200],
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32,vertical:10),
          child: Text(
            "댓글",
            style:TextStyle(
                fontSize: 10,
                color: Colors.grey
            ),
          ),
        ),

        //댓글
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32,vertical:10),
          child:ListView.builder( // 显示评论列表
            shrinkWrap: true,//listview默认占据无限高度，column默认占据一定高度，想要scroll就必须知道自己有多高，所以加了这一行=>一定高度
            physics: NeverScrollableScrollPhysics(),//禁止listview自己滚动
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return ListTile(
                onTap: () {
                  _replyToComment(comment);
                },
                title: Text(comment.nickName),
                leading:CircleAvatar(
                  radius: 20,
                  // backgroundImage: NetworkImage(user.avatarUrl),
                ),
                subtitle: Text(comment.content),
              );
            },
          ),

        ),

      ]
    );
  }

  //입력란
  Widget _buildCommentInput(){
    return Container(
      padding:EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0,0)
          ),
        ],
      ),
      child: _isInputExpanded
          ? _buildExpandedInput()   // 展开状态：完整输入框
          : _buildCollapsedInput(), // 折叠状态：简单提示栏

    );
  }

  //안 열려있을 때의 입력란
  Widget _buildCollapsedInput() {
    return InkWell(
      onTap: () {
        setState(() {
          _isInputExpanded = true;
        });
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

  //열려있을 때의 입력란
  Widget _buildExpandedInput() {
    return Column(
      children: [
        // 如果是回复，显示提示
        if (_replyingTo != null)
          Row(
            children: [
              Text('${_replyingTo!.nickName}님에게 답글:'),
              Spacer(),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _replyingTo = null;
                    _isInputExpanded = false;  // 关闭输入框
                  });
                },
              ),
            ],
          ),

        // 输入框
        Row(
          children: [
            Expanded(
              child: TextField(
                controller:_commentController,

              )
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
      //1. 앱바
      appBar:CustomAppBar(),

      //2. 바디
      body: Container(
          child:Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              //1.윗 작자 구역:고정
              Container(
                height:100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0,0)
                    ),
                  ],
                ),
                //fixed的思路：children里面-fixed的部分放在一个固定高度的container里面括起来，剩下的在children里面继续排列
                child:_buildAuthorSection(),
              ),

              // 2.상세내용
              Expanded(
                child: SingleChildScrollView(
                  child: _buildContentSection(),
                ),
              ),
              // 3.fixed input box:
              // 만약에 댓글을 클릭하지 않았다면: 회신이 아닌 걸로만 나옴
              // 했다면
              _buildCommentInput(),
            ],
          )
      ),

      //밑에 있는 네이버 바
      bottomNavigationBar: BottomAppBar(
        //통일 bottomnaverbar
      ),
    );
  }
}
