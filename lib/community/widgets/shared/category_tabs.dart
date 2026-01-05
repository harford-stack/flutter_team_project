// category tabs: commnity 화면/내가 쓴 게시글/북마크 목록에서 쓰임
// community/widgets/shared/category_tabs.dart

import 'package:flutter/material.dart';
import '../../../common/app_colors.dart';


/// 특징:
/// - 텍스트 + 동적 밑줄만 표시
/// - 동적 밑줄
/// - 배경색, 둥근 모서리, 그림자 없음

class CategoryTabs extends StatelessWidget {

  /// =====================================================================================
  /// 필드
  /// ======================================================================================
  final List<String> categories;
  final String selectedCategory;
  //定义一个变量 onCategoryChanged，它的类型是"接收一个 String 参数的函数"
  final Function(String) onCategoryChanged;

  /// =====================================================================================
  /// 생성자
  /// ======================================================================================
  const CategoryTabs({           // ← 构造函数名（和类名相同）
    Key? key,                    // ← Flutter 内部用的，可选参数
    required this.categories,    // ← 必须传入的参数1：分类列表
    required this.selectedCategory,  // ← 必须传入的参数2：当前选中的分类
    //클릭할 때 콜백함수
    required this.onCategoryChanged, // ← 必须传入的参数3：点击时的回调函数
  }) : super(key: key);          // ← 把 key 传给父类（StatelessWidget）


  /// =====================================================================================
  ///  build method
  /// ======================================================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        //왼쪽으로 align
        mainAxisAlignment: MainAxisAlignment.start,
        //for loop
        children: categories.map((category) {//遍历 categories 列表，每个元素叫 category
          // isSelected: 선택 시 양식을 결정하는 boolean
          final isSelected = selectedCategory == category;//isSelected는 category tabs의 리스트 중의 어느 것(category)과 같을 때 true가 됨
          return GestureDetector(
            //tab를 클릭할 때：
            // onCategoryChanged(category)`는 부모 컴포넌트에 `category`를 전달 (반환 없음)
            // 부모 컴포넌트가 `_selectedCategory`를 직접 업데이트
            // 부모 컴포넌트가 자식 컴포넌트에 새 값 전달
            // 자식 컴포넌트가 `isSelected` 재계산
            onTap: () => onCategoryChanged(category),//也就是说，主要干的事情就是：setState(() => _selectedCategory = category);
            child: Container(
              margin: EdgeInsets.only(right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 文字
                  Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),

                  SizedBox(height: 4),

                  // 동적 밑줄
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut,//Curves.easeInOut:先慢后快
                    width: isSelected ? 50 : 0, // 선택시 너비
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}