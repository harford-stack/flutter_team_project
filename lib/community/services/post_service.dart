// 导入 Firestore 数据库操作相关的包
import 'package:cloud_firestore/cloud_firestore.dart';
// 导入 Post 数据模型
import '../models/post_model.dart';

/// PostService 是一个「专门负责从 Firestore 拿 Post 数据」的服务层
/// 提供帖子数据的查询、过滤、排序等功能
class PostService {
  // Firestore 实例，用于访问数据库
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 获取帖子列表的方法
  ///
  /// 参数说明：
  /// - [searchQuery]: 搜索关键词（可选），用于在标题和内容中搜索
  /// - [sortOrder]: 排序方式，默认为 '시간순'（时间顺序）
  ///   可选值：'시간순'（按时间）、'인기순'（按人气/收藏数）
  /// - [categories]: 分类列表（可选），用于筛选特定分类的帖子
  ///
  /// 返回值：Future<List<Post>> - 异步返回帖子列表
  Future<List<Post>> getPosts({
    String? searchQuery,          // 搜索关键词（可为空）
    String sortOrder = '시간순',   // 排序顺序，默认按时间排序
    List<String>? categories,     // 分类筛选列表（可为空）
  }) async {
    // 创建 Firestore 查询，指向 'post' 集合
    Query query = _firestore.collection('post');

    // 如果提供了分类列表且不为空，则按分类筛选
    // whereIn: 查询 category 字段值在 categories 列表中的文档
    if (categories != null && categories.isNotEmpty) {
      query = query.where('category', whereIn: categories);
    }

    // 根据 sortOrder 参数的值选择不同的排序逻辑
    switch (sortOrder) {
      case '시간순': // 按时间顺序排序
      // 按 cdate（创建日期）字段降序排列（最新的在前）
        query = query.orderBy('cdate', descending: true);
        break;
      case '인기순': // 按人气/热度排序
      // 按 bookmarkCount（收藏数）字段降序排列（收藏数多的在前）
        query = query.orderBy('bookmarkCount', descending: true);
        break;
    }

    // 执行查询，获取快照数据
    final snapshot = await query.get();

    // 将查询结果转换为 Post 对象列表
    // snapshot.docs: 所有查询到的文档
    // .map(): 遍历每个文档，使用 Post.fromFirestore() 将其转换为 Post 对象
    // .toList(): 将映射结果转换为列表
    List<Post> posts = snapshot.docs
        .map((doc) => Post.fromFirestore(doc))
        .toList();

    // 如果提供了搜索关键词且不为空，则进行本地搜索过滤
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // 过滤帖子列表，只保留标题或内容包含搜索关键词的帖子
      posts = posts.where((post) {
        // contains(): 检查字符串是否包含指定的子字符串
        return post.title.contains(searchQuery) ||      // 标题中包含关键词
            post.content.contains(searchQuery);         // 或内容中包含关键词
      }).toList();
    }

    // 返回最终的帖子列表
    return posts;
  }
}