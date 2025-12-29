import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import 'community_detail_screen.dart';

//category model
class Category {
  String name;
  bool isSelected;

  Category({required this.name, this.isSelected = false});
}


class CommunityListScreen extends StatefulWidget {
  const CommunityListScreen({super.key});

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {

  ///변수 선언 구역
  //검색란
  final TextEditingController _searchcontroller = TextEditingController();
  //리스트
  //1.postlist
  List <Post> _posts = [];
  //2.선택된 categories의 리스트
  List<Category> categoryList = [
    Category(name: '자유게시판'),
    Category(name: '문의사항'),
    // 可以添加更多分类
  ];
  //
  bool _isLoading = false;
  //dropdown
  String _sortOrder='시간순';//设置初始化的值

  ///서비스 선언 구역
  final PostService _postService = PostService();

  ///list loading 구역
  //这个页面 / Widget 第一次被创建出来时，只执行一次
  @override
  void initState() {
    super.initState();
    _loadPosts();
  }


  // function:postlist를 로드
  Future<void> _loadPosts() async {
    //步骤1: 开始加载,显示加载动画
    // setState 会触发页面重新构建
    // _isLoading = true 会让 _buildPostList() 显示 CircularProgressIndicator
    setState(() => _isLoading = true);

    // 步骤2: 筛选出用户选中的分类
    // 例如:用户点击了"自由게시판",那么 selectedCategories = ['자유게시판']
    List<String> selectedCategories = categoryList
        .where((cat) => cat.isSelected)// 筛选出 isSelected = true 的分类
        .map((cat) => cat.name)// 只取分类的名字
        .toList();// 转换成 List<String>

    // 步骤3: 调用 PostService,去 Firestore 查询数据
    final posts = await _postService.getPosts(
      searchQuery: _searchcontroller.text,// 搜索框的内容
      sortOrder: _sortOrder, // 排序方式 ('시간순' 或 '인기순')
      categories: selectedCategories, // 传递选中的分类
    );

    // 这里会等待 Firestore 返回数据 (await)
    // getPosts() 函数内部会:
    // 1. 根据 categories 筛选
    // 2. 根据 sortOrder 排序
    // 3. 根据 searchQuery 本地搜索
    // 4. 返回 List<Post>

    // 步骤4: 数据返回后,更新界面
    setState(() {
      _posts = posts;   // 把查询到的帖子列表赋值给 _posts
      _isLoading = false;// 关闭加载动画
    });
    // setState 再次触发页面重新构建
    // 这次 _isLoading = false,会显示帖子列表
  }

  Future<String> getUserAvatar(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if(doc.exists) {
      final data = doc.data()!;
      return data['photoUrl'] ?? '默认头像URL';
    }
    return '默认头像URL';
  }


  ///widget 선언 구역
  //1. 검색
  Widget _buildSearch(){
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      child: Column(
        children: [
          // 第一行：搜索框 + 搜索按钮
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchcontroller,
                  decoration: const InputDecoration(
                    hintText: '게시글 제목이나 내용으로 검색',
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loadPosts,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text("검색"),
              ),
            ],
          ),

          SizedBox(height: 12),

          //第二行：分类按钮 + 排序
          Row(
            children: [
              //자유게시판-문의사항 필터링
              Wrap(
                spacing: 8,
                children: categoryList.map((cat) {
                  return CategoryButton(
                    text: cat.name,
                    isSelected: cat.isSelected,
                    onTap: () {
                      setState(() {
                        cat.isSelected = !cat.isSelected;
                        categoryList = List.from(categoryList);
                      });
                      _loadPosts();
                    },
                  );
                }).toList(),
              ),

              Spacer(), // 把排序推到右边

              //dropdown
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<String>(
                  value: _sortOrder,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: '시간순', child: Text('시간순', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: '인기순', child: Text('인기순', style: TextStyle(fontSize: 14))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortOrder = value!;
                    });
                    _loadPosts();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //2. 게시글 목록
  Widget _buildPostList() {
    //로딩
    // 加载中
    if (_isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    //빈 데이터
    // 空数据
    if (_posts.isEmpty) {
      return const Expanded(
        child: Center(child: Text('게시글이 없습니다')),
      );
    }

    // post 목록
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,//width:height
          ),
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            final post = _posts[index];
            return Card(
              child: InkWell(
                onTap: () {
                  //detail에 들어가기
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(postId: post.id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 이미지
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: post.thumbnailUrl.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            post.thumbnailUrl, // 显示第一张图片
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                        )
                            : const Center(
                          child: Icon(Icons.image, size: 40, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 8),
                      //제목
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      // 작성자
                      Row(
                        //avatar
                        children: [
                          CircleAvatar(
                            radius:10,
                            // backgroundImage: ,
                          ),
                          SizedBox(width:8),
                          Text(
                            post.nickName,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 浏览数和点赞数
                      Row(
                        //不能用alignment,因为row里面的没有撑满,对他不起作用
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.comment, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${post.commentCount}', style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 12),
                          const Icon(Icons.bookmark, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${post.bookmarkCount}', style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  //dispose
  @override
  void dispose(){
    _searchcontroller.dispose();
    super.dispose();
  }

  ///화면 구역
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
              //2.1 검색란
              _buildSearch(),
              _buildPostList(),
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


class CategoryButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryButton({
    Key? key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[400]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}