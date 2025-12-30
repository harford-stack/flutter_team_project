import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import 'community_detail_screen.dart';
import 'post_editor_screen.dart'; // ⭐ 新增

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

  ///变量 选언 구역
  final TextEditingController _searchcontroller = TextEditingController();
  List <Post> _posts = [];
  List<Category> categoryList = [
    Category(name: '자유게시판'),
    Category(name: '문의사항'),
  ];
  bool _isLoading = false;
  String _sortOrder='시간순';

  ///서비스 선언 구역
  final PostService _postService = PostService();

  ///list loading 구역
  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  // function:postlist를 로드
  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    List<String> selectedCategories = categoryList
        .where((cat) => cat.isSelected)
        .map((cat) => cat.name)
        .toList();

    final posts = await _postService.getPosts(
      searchQuery: _searchcontroller.text,
      sortOrder: _sortOrder,
      categories: selectedCategories,
    );

    setState(() {
      _posts = posts;
      _isLoading = false;
    });
  }

  Future<String> getUserAvatar(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if(doc.exists) {
      final data = doc.data()!;
      return data['photoUrl'] ?? '默认头像URL';
    }
    return '默认头像URL';
  }

  // ⭐ 新增：导航到创建页面
  Future<void> _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostEditorScreen(), // 不传 existingPost = 创建模式
      ),
    );

    // 如果创建成功，刷新列表
    if (result == true) {
      await _loadPosts();
    }
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

              Spacer(),

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
    if (_isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_posts.isEmpty) {
      return const Expanded(
        child: Center(child: Text('게시글이 없습니다')),
      );
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            final post = _posts[index];
            return Card(
              child: InkWell(
                onTap: () async {
                  // ⭐ 修改：从详情页返回时刷新列表
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(postId: post.id),
                    ),
                  );
                  // 返回时刷新列表（因为可能删除了帖子）
                  _loadPosts();
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
                            post.thumbnailUrl,
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
                        children: [
                          CircleAvatar(
                            radius:10,
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

  @override
  void dispose(){
    _searchcontroller.dispose();
    super.dispose();
  }

  ///화면 구역
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        title: Text('커뮤니티'),
        actions: [
          // ⭐ 新增：创建帖子按钮
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _navigateToCreatePost,
            tooltip: '게시글 작성',
          ),
        ],
      ),

      body: Container(
          child:Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildSearch(),
              _buildPostList(),
            ],
          )
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