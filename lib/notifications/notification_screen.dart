// lib/notifications/notification_screen.dart

import 'package:flutter/material.dart';
import 'notification_tab.dart';

/// 通知页面入口
///
/// 说明：
/// 这个文件只是一个简单的入口，实际的通知功能都在 notification_tab.dart 中实现
/// 这样做的好处是：
/// 1. 保持文件职责单一
/// 2. 方便在其他地方复用 NotificationTab
/// 3. 未来如果需要添加额外的包装逻辑，可以在这里处理
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 直接返回 NotificationTab widget
    // 所有的 Tab 切换、通知列表、点击跳转等功能都在 NotificationTab 中
    return NotificationTab();
  }
}