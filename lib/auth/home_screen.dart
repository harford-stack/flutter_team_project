import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/app_colors.dart';
import '../common/custom_appbar.dart';
import '../common/custom_footer.dart';
import '../ingredients/regist_screen.dart';
import '../community/community_list_widget.dart';
import 'auth_provider.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onFooterTap(int index, AuthProvider authProvider) {
    // 로그인이 필요한 메뉴 (재료 등록, 커뮤니티)
    if (index == 1 || index == 2) {
      if (!authProvider.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 필요한 메뉴입니다.'),
            backgroundColor: Colors.orange,
          ),
        );
        // 로그인 화면으로 이동
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const IngredientRegistScreen();
      case 2:
        return const CommunityListWidget();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // "어플 이름" (AppBar에 이미 있지만, 필요시 추가)
          const Text(
            '어플 이름',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 40),
          // "레시피 추천 받기" 버튼 (비로그인 사용자도 이용 가능)
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('레시피 추천 기능은 추후 구현 예정입니다')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              '레시피 추천 받기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: _buildDrawer(authProvider),
      body: _buildCurrentScreen(),
      bottomNavigationBar: CustomFooter(
        currentIndex: _currentIndex,
        onTap: (index) => _onFooterTap(index, authProvider),
      ),
    );
  }

  Widget _buildDrawer(AuthProvider authProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: authProvider.isAuthenticated &&
                          authProvider.user?.photoURL != null
                      ? ClipOval(
                          child: Image.network(
                            authProvider.user!.photoURL!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.primaryColor,
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  authProvider.isAuthenticated
                      ? (authProvider.user?.displayName ?? '사용자')
                      : '로그인 후 이용하세요',
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (authProvider.isAuthenticated &&
                    authProvider.user?.email != null)
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
            ),
          ),
          if (authProvider.isAuthenticated) ...[
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('프로필'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('프로필 기능은 추후 구현 예정입니다')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('설정'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('설정 기능은 추후 구현 예정입니다')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
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
          ] else ...[
            ListTile(
              leading: const Icon(Icons.login),
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
