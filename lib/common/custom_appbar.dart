import 'package:flutter/material.dart';
import 'app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String appName;
  final Widget? customTitle;
  final VoidCallback? onNotificationTap;

  const CustomAppBar({
    super.key,
    this.appName = '어플 이름',
    this.customTitle,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Image.asset(
            'assets/icon_menu.png',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      centerTitle: true,
      title: customTitle ?? Text(
        appName,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Image.asset(
            'assets/icon_notification.png',
            width: 24,
            height: 24,
          ),
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

