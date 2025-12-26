import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
///PostService 是一个「专门负责从 Firestore 拿 Post 数据」的服务层


class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //最终返回的是List<Post>
  Future<List<Post>> getPosts({//Future:异步；最终返回的是<List<Post>>,参数是searchQuery和sortOrder
    String? searchQuery,
    String sortOrder = '시간순',
    List<String>? categories,
  }) async {
    Query query = _firestore.collection('post');

    if (categories != null && categories.isNotEmpty) {
      query = query.where('category', whereIn: categories);
    }
    //switch (sortOrder)
    // 根据 sortOrder 的值选择不同的排序逻辑。
    switch (sortOrder) {
      case '시간순':
        query = query.orderBy('cdate', descending: true);
        break;
      case '인기순':
        query = query.orderBy('bookmarkCount', descending: true);
        break;
    }

    final snapshot = await query.get();

    List<Post> posts = snapshot.docs
        .map((doc) => Post.fromFirestore(doc))
        .toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      posts = posts.where((post) {
        return post.title.contains(searchQuery) ||
            post.content.contains(searchQuery);
      }).toList();
    }

    return posts;
  }
}