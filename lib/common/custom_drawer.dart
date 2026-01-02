import 'package:flutter/material.dart';
import 'package:flutter_team_project/community/screens/bookmark_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/home_screen.dart';
import 'app_colors.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import '../auth/delete_account_screen.dart';
import '../auth/profile_edit_screen.dart';
import '../recipes/my_recipes_screen.dart';
import 'package:flutter_team_project/community/screens/my_post_list_screen.dart';
import '../ingredients/user_ingredient_regist.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.white,
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
                          Text(
                            nickname,
                            style: const TextStyle(
                              color: AppColors.textDark,
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
                                  color: AppColors.textDark,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  )
                : const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '로그인 후 이용하세요',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
          ListTile(
            leading: Image.asset(
              'assets/icon_home.png',
              width: 24,
              height: 24,
            ),
            title: const Text('홈'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
                (route) => false,
              );
            },
          ),
          if (authProvider.isAuthenticated)
            ListTile(
              leading: Image.asset(
                'assets/icon_fridge.png',
                width: 24,
                height: 24,
              ),
              title: const Text('내 냉장고 재료'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const UserIngredientRegist(),
                  ),
                );
              },
            ),
          if (authProvider.isAuthenticated) ...[
            const Divider(),
            ListTile(
              leading: Image.asset(
                'assets/icon_myrecipe.png',
                width: 24,
                height: 24,
              ),
              title: const Text('나의 레시피'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyRecipesScreen(),
                  ),
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BookmarkListScreen(),
                  ),
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyPostListScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Image.asset(
                'assets/icon_profile.png',
                width: 24,
                height: 24,
              ),
              title: const Text('프로필 수정'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileEditScreen(),
                  ),
                );
              },
            ),
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
                // 홈 화면으로 이동 내용 추가! & 이전의 모든 스택을 제거
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                );
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

