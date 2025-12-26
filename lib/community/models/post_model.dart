import 'package:cloud_firestore/cloud_firestore.dart';

///post是一个数据模型,专门负责数据形状,不负责ui,不负责逻辑

/// “一篇帖子，由这些信息组成：
//1.定义字段名
//2.定义字段类型
//3.规定哪些一定有、哪些可以没有
class Post {
  final String id;
  final String title;
  final String content;
  final String category;
  final String userId;
  final String nickName;
  final int commentCount;
  final int bookmarkCount;
  final String thumbnailUrl;
  final DateTime cdate;
  final DateTime? udate; // 更新时间（可能为null）=>type后面加问号

  ///构造函数
  //“你要造一个 Post，就必须一次性把这些值都给我（udate 除外）。”
  //跟上面的区分：上面的只说明“这个数据存不存在这种可能“，required 才说明“创建这个对象时，给不给你创建的权利。
  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.userId,
    required this.nickName,
    required this.commentCount,
    required this.bookmarkCount,
    required this.thumbnailUrl,
    required this.cdate,
    this.udate,
  });

  // 从 Firestore 转换
  //进来
  //这整个 fromFirestore 的作用只有一个：把 Firestore 里的一条 document，翻译成一个 Dart 世界里的 Post 对象。
  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Post(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? '',
      userId: data['userId'] ?? '',
      nickName:data['nickName'] ??'익명',
      commentCount: data['commentCount'] ?? 0,
      bookmarkCount: data['bookmarkCount'] ?? 0,
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      cdate: (data['cdate'] as Timestamp).toDate(),//Firestore 里的时间不是 DateTime，而是 Timestamp，Flutter 里要用，必须手动把它“转型”。
      udate: data['udate'] != null
          ? (data['udate'] as Timestamp).toDate()
          : null,
    );
  }

  //转换为 Map
  //出去
  Map<String, dynamic> toMap() {
    return {
      //不要往里面存id
      'title': title,
      'content': content,
      'category': category,
      'userId': userId,
      'nickName': nickName,
      'commentCount':commentCount,
      'bookmarkCount':bookmarkCount,
      'thumbnailUrl':thumbnailUrl,
      'cdate': Timestamp.fromDate(cdate),
      'udate': udate != null ? Timestamp.fromDate(udate!) : null,
    };
  }
}