// // community/widgets/community_list/search_section.dart
// //잠시 사용 포기
// import 'package:flutter/material.dart';
// import '../../../common/app_colors.dart';
//
// /// 搜索区域组件
// class SearchSection extends StatelessWidget {
//   final TextEditingController searchController;
//   final VoidCallback onSearch;
//   final List<CategoryButton> categoryButtons;
//   final String sortOrder;
//   final Function(String?) onSortChanged;
//
//   const SearchSection({
//     Key? key,
//     required this.searchController,
//     required this.onSearch,
//     required this.categoryButtons,
//     required this.sortOrder,
//     required this.onSortChanged,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       color: Colors.white,
//       child: Column(
//         children: [
//           // 第一行：搜索框 + 搜索按钮
//           Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   controller: searchController,
//                   decoration: InputDecoration(
//                     hintText: '게시글 제목이나 내용으로 검색',
//                     contentPadding: const EdgeInsets.symmetric(
//                       vertical: 8,
//                       horizontal: 8,
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide(color: Colors.grey),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide(
//                         color: AppColors.secondaryColor,
//                         width: 2,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(width: 8),
//               ElevatedButton(
//                 onPressed: onSearch,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 8,
//                   ),
//                   textStyle: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   backgroundColor: AppColors.primaryColor,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: Text(
//                   "검색",
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//
//           SizedBox(height: 12),
//
//           // 第二行：分类按钮 + 排序
//           Row(
//             children: [
//               // 分类按钮
//               Wrap(
//                 spacing: 8,
//                 children: categoryButtons,
//               ),
//
//               Spacer(),
//
//               // 排序下拉框
//               SizedBox(
//                 width: 110,
//                 child: DropdownButtonFormField<String>(
//                   value: sortOrder,
//                   decoration: InputDecoration(
//                     isDense: true,
//                     contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 10,
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide(color: Colors.grey),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide(
//                         color: AppColors.secondaryColor,
//                         width: 2,
//                       ),
//                     ),
//                   ),
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Colors.black87,
//                   ),
//                   dropdownColor: Colors.white,
//                   isExpanded: true,
//                   items: const [
//                     DropdownMenuItem(value: '시간순', child: Text('시간순')),
//                     DropdownMenuItem(value: '인기순', child: Text('인기순')),
//                   ],
//                   onChanged: onSortChanged,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// /// 分类按钮
// class CategoryButton extends StatelessWidget {
//   final String text;
//   final bool isSelected;
//   final VoidCallback onTap;
//
//   const CategoryButton({
//     Key? key,
//     required this.text,
//     required this.isSelected,
//     required this.onTap,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//         decoration: BoxDecoration(
//           color: isSelected ? AppColors.primaryColor : Colors.white,
//           borderRadius: BorderRadius.circular(4),
//           border: Border.all(
//             color: isSelected ? AppColors.primaryColor : Colors.grey[400]!,
//             width: isSelected ? 2 : 1,
//           ),
//         ),
//         child: Text(
//           text,
//           style: TextStyle(
//             color: isSelected ? Colors.white : Colors.black,
//             fontSize: 14,
//             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//       ),
//     );
//   }
// }