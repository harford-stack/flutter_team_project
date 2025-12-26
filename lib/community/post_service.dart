// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/post_model.dart';
//
// class PostService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final String collectionName = 'post';
//
//   // 获取所有帖子（带排序和搜索）
//   Future<List<Post>> getPosts({
//     String? searchQuery,
//     String sortOrder = '시간순',
//   }) async {
//     try {
//       Query query = _firestore.collection(collectionName);
//
//       // 根据排序方式设置查询
//       switch (sortOrder) {
//         case '시간순':
//           query = query.orderBy('createdAt', descending: true);
//           break;
//         case '조회순':
//           query = query.orderBy('views', descending: true);
//           break;
//         case '인기순':
//           query = query.orderBy('likes', descending: true);
//           break;
//       }
//
//       final snapshot = await query.get();
//
//       // 转换为 Post 对象列表
//       List<Post> posts = snapshot.docs
//           .map((doc) => Post.fromFirestore(doc))
//           .toList();
//
//       // 如果有搜索关键词，在客户端过滤
//       // （Firestore 不支持全文搜索，需要在客户端过滤）
//       if (searchQuery != null && searchQuery.isNotEmpty) {
//         posts = posts.where((post) {
//           return post.title.contains(searchQuery) ||
//               post.content.contains(searchQuery);
//         }).toList();
//       }
//
//       return posts;
//     } catch (e) {
//       print('Error getting posts: $e');
//       return [];
//     }
//   }
//
//   // 创建帖子
//   Future<void> createPost(Post post) async {
//     try {
//       await _firestore.collection(collectionName).add(post.toMap());
//     } catch (e) {
//       print('Error creating post: $e');
//       rethrow;
//     }
//   }
//
//   // 更新帖子
//   Future<void> updatePost(String postId, Map<String, dynamic> data) async {
//     try {
//       await _firestore
//           .collection(collectionName)
//           .doc(postId)
//           .update(data);
//     } catch (e) {
//       print('Error updating post: $e');
//       rethrow;
//     }
//   }
//
//   // 删除帖子
//   Future<void> deletePost(String postId) async {
//     try {
//       await _firestore.collection(collectionName).doc(postId).delete();
//     } catch (e) {
//       print('Error deleting post: $e');
//       rethrow;
//     }
//   }
// }