import 'package:flutter/material.dart';
import 'app_colors.dart';

class CustomFooter extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / 3;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: _buildFooterItem(
                        icon: null,
                        iconAsset: 'assets/icon/icon_recipe.png',
                        label: '레시피',
                        index: 0,
                        isSelected: currentIndex == 0,
                      ),
                    ),

                    Container(width: 1, height: 30, color: Colors.grey[300]),

                    Expanded(
                      child: _buildFooterItem(
                        icon: null,
                        iconAsset: 'assets/icon/icon_refrigerator.png',
                        label: '내 냉장고',
                        index: 1,
                        isSelected: currentIndex == 1,
                      ),
                    ),

                    Container(width: 1, height: 30, color: Colors.grey[300]),

                    Expanded(
                      child: _buildFooterItem(
                        icon: null,
                        iconAsset: 'assets/icon/icon_community.png',
                        label: '커뮤니티',
                        index: 2,
                        isSelected: currentIndex == 2,
                      ),
                    ),
                  ],
                ),
                // 선택된 항목 위쪽 라인 (푸터 영역 윗라인에 겹쳐서)
                // currentIndex가 -1이면 아무 라인도 표시하지 않음
                if (currentIndex == 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    width: itemWidth,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  )
                else if (currentIndex == 1)
                  Positioned(
                    top: 0,
                    left: itemWidth,
                    width: itemWidth,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  )
                else if (currentIndex == 2)
                  Positioned(
                    top: 0,
                    left: itemWidth * 2,
                    width: itemWidth,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFooterItem({
    required IconData? icon,
    required String? iconAsset,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (iconAsset != null)
              ColorFiltered(
                colorFilter: isSelected
                    ? ColorFilter.mode(
                        AppColors.primaryColor,
                        BlendMode.srcIn,
                      )
                    : const ColorFilter.matrix(<double>[
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0,      0,      0,      1, 0,
                      ]),
                child: Image.asset(
                  iconAsset,
                  width: 24,
                  height: 24,
                ),
              )
            else if (icon != null)
              Icon(
                icon,
                color: isSelected ? AppColors.primaryColor : Colors.grey[600],
                size: 24,
              ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? AppColors.primaryColor : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
