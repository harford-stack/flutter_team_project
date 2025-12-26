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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFooterItem(
            icon: Icons.home,
            label: '홈',
            index: 0,
            isSelected: currentIndex == 0,
          ),
          _buildFooterItem(
            icon: Icons.add_circle_outline,
            label: '재료 등록',
            index: 1,
            isSelected: currentIndex == 1,
          ),
          _buildFooterItem(
            icon: Icons.people_outline,
            label: '커뮤니티',
            index: 2,
            isSelected: currentIndex == 2,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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

