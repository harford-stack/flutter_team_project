import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Post>> getPosts({
    String? searchQuery,
    String sortOrder = '시간순',
  }) async {
    Query query = _firestore.collection('post');

    // 排序
    switch (sortOrder) {
      case '시간순':
        query = query.orderBy('createdAt', descending: true);
        break;
      case '조회순':
        query = query.orderBy('views', descending: true);
        break;
      case '인기순':
        query = query.orderBy('likes', descending: true);
        break;
    }

    final snapshot = await query.get();
    List<Post> posts = snapshot.docs
        .map((doc) => Post.fromFirestore(doc))
        .toList();

    // 搜索过滤
    if (searchQuery != null && searchQuery.isNotEmpty) {
      posts = posts.where((post) {
        return post.title.contains(searchQuery) ||
            post.content.contains(searchQuery);
      }).toList();
    }

    return posts;
  }
}