import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/post_model.dart';

/// PostService 扩展版 - 包含 CRUD 完整功能
class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// ========== 查询功能（保留原有代码）==========
  Future<List<Post>> getPosts({
    String? searchQuery,
    String sortOrder = '시간순',
    List<String>? categories,
  }) async {
    Query query = _firestore.collection('post');

    if (categories != null && categories.isNotEmpty) {
      query = query.where('category', whereIn: categories);
    }

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

  /// ========== 创建帖子 ==========
  /// 参数:
  /// - title: 标题
  /// - content: 内容
  /// - category: 分类
  /// - userId: 用户ID
  /// - nickName: 用户昵称
  /// - imageFile: 图片文件（可选）
  /// 返回: 成功返回帖子ID，失败返回null
  Future<String?> createPost({
    required String title,
    required String content,
    required String category,
    required String userId,
    required String nickName,
    File? imageFile,
  }) async {
    try {
      String thumbnailUrl = '';

      // 如果有图片，先上传到 Firebase Storage
      if (imageFile != null) {
        thumbnailUrl = await _uploadImage(imageFile, userId);
      }

      // 创建帖子数据
      final postData = {
        'title': title,
        'content': content,
        'category': category,
        'userId': userId,
        'nickName': nickName,
        'commentCount': 0,
        'bookmarkCount': 0,
        'thumbnailUrl': thumbnailUrl,
        'imageUrls': thumbnailUrl.isNotEmpty ? [thumbnailUrl] : [],
        'cdate': Timestamp.now(),
        'udate': null,
      };

      // 添加到 Firestore
      final docRef = await _firestore.collection('post').add(postData);

      print('게시글 작성 성공: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('게시글 작성 실패: $e');
      return null;
    }
  }

  /// ========== 修改帖子 ==========
  /// 参数:
  /// - postId: 帖子ID
  /// - title: 新标题
  /// - content: 新内容
  /// - category: 新分类
  /// - newImageFile: 新图片（可选，如果不传则保留原图）
  /// - deleteImage: 是否删除原图
  /// 返回: bool - true=成功, false=失败
  Future<bool> updatePost({
    required String postId,
    required String title,
    required String content,
    required String category,
    File? newImageFile,
    bool deleteImage = false,
  }) async {
    try {
      // 获取原帖子数据
      final docSnapshot = await _firestore.collection('post').doc(postId).get();
      if (!docSnapshot.exists) {
        print('게시글을 찾을 수 없습니다');
        return false;
      }

      final oldData = docSnapshot.data()!;
      String thumbnailUrl = oldData['thumbnailUrl'] ?? '';

      // 处理图片更新逻辑
      if (deleteImage && thumbnailUrl.isNotEmpty) {
        // 删除旧图片
        await _deleteImage(thumbnailUrl);
        thumbnailUrl = '';
      } else if (newImageFile != null) {
        // 如果有旧图，先删除
        if (thumbnailUrl.isNotEmpty) {
          await _deleteImage(thumbnailUrl);
        }
        // 上传新图
        thumbnailUrl = await _uploadImage(newImageFile, oldData['userId']);
      }

      // 更新帖子数据
      final updateData = {
        'title': title,
        'content': content,
        'category': category,
        'thumbnailUrl': thumbnailUrl,
        'imageUrls': thumbnailUrl.isNotEmpty ? [thumbnailUrl] : [],
        'udate': Timestamp.now(),
      };

      await _firestore.collection('post').doc(postId).update(updateData);

      print('게시글 수정 성공');
      return true;
    } catch (e) {
      print('게시글 수정 실패: $e');
      return false;
    }
  }

  /// ========== 删除帖子 ==========
  /// 参数: postId - 帖子ID
  /// 返回: bool - true=成功, false=失败
  Future<bool> deletePost(String postId) async {
    try {
      // 1. 获取帖子数据
      final docSnapshot = await _firestore.collection('post').doc(postId).get();
      if (!docSnapshot.exists) {
        print('게시글을 찾을 수 없습니다');
        return false;
      }

      final data = docSnapshot.data()!;
      final thumbnailUrl = data['thumbnailUrl'] ?? '';

      // 2. 删除图片（如果有）
      if (thumbnailUrl.isNotEmpty) {
        await _deleteImage(thumbnailUrl);
      }

      // 3. 删除所有评论
      final commentsSnapshot = await _firestore
          .collection('post')
          .doc(postId)
          .collection('comment')
          .get();

      for (var doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // 4. 删除所有收藏记录
      final bookmarksSnapshot = await _firestore
          .collection('post')
          .doc(postId)
          .collection('bookmarks')
          .get();

      for (var doc in bookmarksSnapshot.docs) {
        await doc.reference.delete();
      }

      // 5. 删除帖子本身
      await _firestore.collection('post').doc(postId).delete();

      print('게시글 삭제 성공');
      return true;
    } catch (e) {
      print('게시글 삭제 실패: $e');
      return false;
    }
  }

  /// ========== 辅助方法：上传图片 ==========
  Future<String> _uploadImage(File imageFile, String userId) async {
    try {
      print('📤 开始上传图片...');
      print('📁 文件路径: ${imageFile.path}');
      print('📁 文件是否存在: ${await imageFile.exists()}');

      final fileName = 'posts/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('📁 Storage 路径: $fileName');

      final ref = _storage.ref().child(fileName);

      print('⬆️ 正在上传...');
      await ref.putFile(imageFile);

      print('✅ 上传成功，获取 URL...');
      final downloadUrl = await ref.getDownloadURL();

      print('✅ URL 获取成功: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ 이미지 업로드 실패: $e');
      print('❌ 错误类型: ${e.runtimeType}');
      return '';
    }
  }

  /// ========== 辅助方法：删除图片 ==========
  Future<void> _deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;

      // 从 URL 中提取 Storage 路径
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('이미지 삭제 성공');
    } catch (e) {
      print('이미지 삭제 실패: $e');
    }
  }
}