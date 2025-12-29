import 'package:cloud_firestore/cloud_firestore.dart';

///post是一个数据模型,专门负责数据形状,不负责ui,不负责逻辑

/// “一篇帖子，由这些信息组成：
//1.定义字段名
//2.定义字段类型
//3.规定哪些一定有、哪些可以没有
class Comment{
  final String id;
  final String postId;
  final String? pComment;
  final String content;
  final String userId;
  final String nickName;
  final DateTime cdate;
  final DateTime? udate; // 更新时间（可能为null）=>type后面加问号

  ///构造函数
  Comment({
    required this.id,
    required this.postId,
    this.pComment,
    required this.content,
    required this.userId,
    required this.nickName,
    required this.cdate,
    this.udate,
  });

  // 从 Firestore 转换
  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Comment(
      id: doc.id,
      postId: data['postId'] ?? '',
      pComment:data['pComment'] != null
          ? data['pComment'] as String
          : null,
      content: data['content'] ?? '',
      userId: data['userId'] ?? '',
      nickName:data['nickName'] ??'익명',
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
      'postId': postId,
      'content': content,
      'pComment': pComment != null ? pComment: null,
      'userId': userId,
      'nickName': nickName,
      'cdate': Timestamp.fromDate(cdate),
      'udate': udate != null ? Timestamp.fromDate(udate!) : null,
    };
  }
}