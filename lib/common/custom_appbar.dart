import 'package:flutter/material.dart';
import 'app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String appName;
  final VoidCallback? onNotificationTap;

  const CustomAppBar({
    super.key,
    this.appName = '어플 이름',
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.backgroundColor,
      elevation: 1,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textDark),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      centerTitle: true,
      title: Text(
        appName,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.textDark),
          onPressed: onNotificationTap ?? () {
            // 알림 기능 (추후 구현)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('알림 기능은 추후 구현 예정입니다')),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

