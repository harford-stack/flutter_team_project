// // community/widgets/community_detail/author_section.dart
//
// import 'package:flutter/material.dart';
// import '../../models/post_model.dart';
// import '../../../common/app_colors.dart';
//
// /// 作者信息栏容器（带高度和阴影）
// class AuthorSectionContainer extends StatelessWidget {
//   final Post post;
//   final bool isMyPost;
//   final bool isBookmarked;
//   final VoidCallback onEdit;
//   final VoidCallback onDelete;
//   final VoidCallback onBookmark;
//
//   const AuthorSectionContainer({
//     Key? key,
//     required this.post,
//     required this.isMyPost,
//     required this.isBookmarked,
//     required this.onEdit,
//     required this.onDelete,
//     required this.onBookmark,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 100,
//       decoration: BoxDecoration(
//         color: AppColors.backgroundColor,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: Offset(0, 0),
//           ),
//         ],
//       ),
//       child: AuthorSection(
//         post: post,
//         isMyPost: isMyPost,
//         isBookmarked: isBookmarked,
//         onEdit: onEdit,
//         onDelete: onDelete,
//         onBookmark: onBookmark,
//       ),
//     );
//   }
// }
//
// /// 作者信息栏组件
// class AuthorSection extends StatelessWidget {
//   final Post post;
//   final bool isMyPost;
//   final bool isBookmarked;
//   final VoidCallback onEdit;
//   final VoidCallback onDelete;
//   final VoidCallback onBookmark;
//
//   const AuthorSection({
//     Key? key,
//     required this.post,
//     required this.isMyPost,
//     required this.isBookmarked,
//     required this.onEdit,
//     required this.onDelete,
//     required this.onBookmark,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 12,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       padding: EdgeInsets.all(16),
//       child: Row(
//         children: [
//           SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   post.nickName,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (isMyPost) ...[
//             IconButton(
//               icon: Icon(Icons.edit, color: AppColors.primaryColor),
//               onPressed: onEdit,
//               tooltip: '수정',
//             ),
//             IconButton(
//               icon: Icon(Icons.delete, color: AppColors.primaryColor),
//               onPressed: onDelete,
//               tooltip: '삭제',
//             ),
//           ],
//           // IconButton(
//             icon: Icon
//               isBookmarked ? Icons.bookmark : Icons.bookmark_border,
//               color: isBookmarked ? Colors.yellow[700] : Colors.grey,
//             ),
//             onPressed: onBookmark,
//           ),
//         ],
//       ),
//     );
//   }
// }