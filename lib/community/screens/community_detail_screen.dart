import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_detail_service.dart';

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
  bool _isLoading = false;//로딩 상태
  bool _isBookmarked = false;// 북마크 상태


  ///서비스 선언 구역=====================================
  final PostDetailService _detailService = PostDetailService();

  ///페이지 초기화 구역=============================================
  @override
  void initState() {
    super.initState();
    _loadPostDetail();
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
  Future<void> _toggleBookmark() async {
    if (_post == null) return;

    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    await _detailService.toggleBookmark(widget.postId, _isBookmarked);

    // 重新加载以更新收藏数
    _loadPostDetail();
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
        // Padding(
        //     padding: EdgeInsets.symmetric(horizontal: 32,vertical:10),
        //     child: Text(
        //       _post!.cdate,
        //       style:TextStyle(
        //         fontSize: 10,
        //         color: Colors.grey
        //       ),
        //
        //     )
        // ),

        //중간에 분간하는 선
        Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey,
        ),

        //댓글
        Padding(
          padding: EdgeInsets.all(16),

        ),
      ]
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //1. 앱바
      appBar:AppBar(
        //통일 appBar

      ),

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

              //3.fixed 댓글 작성란
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
