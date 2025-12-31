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
    return Container(
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
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildFooterItem(
              icon: null,
              iconAsset: 'assets/icon_home.png',
              label: '홈',
              index: 0,
              isSelected: currentIndex == 0,
            ),
          ),

          Container(width: 1, height: 30, color: Colors.grey[300]),

          Expanded(
            child: _buildFooterItem(
              icon: null,
              iconAsset: 'assets/icon_add.png',
              label: '재료 등록',
              index: 1,
              isSelected: currentIndex == 1,
            ),
          ),

          Container(width: 1, height: 30, color: Colors.grey[300]),

          Expanded(
            child: _buildFooterItem(
              icon: null,
              iconAsset: 'assets/icon_community.png',
              label: '커뮤니티',
              index: 2,
              isSelected: currentIndex == 2,
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconAsset != null)
              ColorFiltered(
                colorFilter: isSelected
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0,      0,      0,      1, 0,
                    ]),
                child: Image.asset(
                  iconAsset,
                  width: 28,
                  height: 28,
                ),
              )
            else if (icon != null)
              Icon(
                icon,
                color: isSelected ? AppColors.primaryColor : Colors.grey[600],
                size: 28,
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primaryColor : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

