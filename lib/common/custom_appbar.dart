import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_colors.dart';
import '../auth/auth_provider.dart';
import '../auth/home_screen.dart';
import '../notifications/notification_service.dart';
import '../notifications/notification_screen.dart';

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
            'assets/icon/icon_burgerMenu.png',
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
        // 홈 아이콘
        IconButton(
          icon: Image.asset(
            'assets/icon/icon_home.png',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
              (route) => false,
            );
          },
        ),
        // ✅ 修改通知图标部分,添加红点
        _buildNotificationButton(context),
      ],
    );
  }

  // 빨간점이 있는 알림 버튼
  // ✅ 修改 StreamBuilder 部分
  Widget _buildNotificationButton(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      return IconButton(
        icon: Image.asset('assets/icon/icon_bell.png', width: 24, height: 24),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인이 필요합니다')),
          );
        },
      );
    }

    // Stream 바르게 초기화하기를 확정
    final notificationService = NotificationService();

    return StreamBuilder<int>(
      stream: notificationService.getUnreadCountStream(currentUser.uid),
      builder: (context, snapshot) {
        // 添加调试日志
        print('읽지 않았던 알림 수: ${snapshot.data}');

        final unreadCount = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none, // 允许红点超出边界
          children: [
            IconButton(
              icon: Image.asset('assets/icon/icon_bell.png', width: 24, height: 24),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationScreen()),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}