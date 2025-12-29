import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_colors.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import '../auth/delete_account_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
            ),
            child: authProvider.isAuthenticated && authProvider.user != null
                ? FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(authProvider.user!.uid)
                        .get(),
                    builder: (context, snapshot) {
                      String nickname = '사용자';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        nickname = data?['nickname'] ?? 
                                  authProvider.user?.displayName ?? 
                                  '사용자';
                      } else {
                        nickname = authProvider.user?.displayName ?? '사용자';
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Image.asset(
                              'assets/icon_profile.png',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            nickname,
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (authProvider.user?.email != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                authProvider.user!.email!,
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Image.asset(
                          'assets/icon_profile.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '로그인 후 이용하세요',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
          if (authProvider.isAuthenticated) ...[
            ListTile(
              leading: Image.asset(
                'assets/icon_myrecipe.png',
                width: 24,
                height: 24,
              ),
              title: const Text('나의 레시피'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('나의 레시피 기능은 구현 중입니다')),
                );
              },
            ),
            ListTile(
              leading: Image.asset(
                'assets/icon_bookmarklist.png',
                width: 24,
                height: 24,
              ),
              title: const Text('북마크 목록'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('북마크 목록 기능은 구현 중입니다')),
                );
              },
            ),
            ListTile(
              leading: Image.asset(
                'assets/icon_myposts.png',
                width: 24,
                height: 24,
              ),
              title: const Text('내가 쓴 게시글'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('내가 쓴 게시글 기능은 구현 중입니다')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Image.asset(
                'assets/icon_logout.png',
                width: 24,
                height: 24,
              ),
              title: const Text('로그아웃'),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('로그아웃되었습니다'),
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
              },
            ),
            ListTile(
              leading: Image.asset(
                'assets/icon_delete.png',
                width: 24,
                height: 24,
              ),
              title: const Text('계정정보 삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DeleteAccountScreen(),
                  ),
                );
              },
            ),
          ] else ...[
            ListTile(
              leading: Image.asset(
                'assets/icon_login.png',
                width: 24,
                height: 24,
              ),
              title: const Text('로그인'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

