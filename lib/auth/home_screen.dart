import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/app_colors.dart';
import '../common/custom_appbar.dart';
import '../common/custom_footer.dart';
import '../common/custom_drawer.dart';
import '../ingredients/user_ingredient_regist.dart';
import '../community/screens/community_list_screen.dart';
// import '../community/widgets/community_list_widget.dart';
import 'auth_provider.dart';
import 'login_screen.dart';
import 'recipe_recommend_screen.dart';
import '../notifications/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

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
        return const UserIngredientRegist();
      case 2:
        return const CommunityListScreen();
        // return const CommunityListWidget();
        return _buildHomeContent();
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
          // 레시피 추천 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/icon_recommendImage.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          // 코드로 구현한 레시피 추천 섹션
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  '레시피',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                const Text(
                  '추천 받기',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '재료만 입력하면',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textWhite,
                  ),
                ),
                const Text(
                  '딱 맞는 레시피를 추천해드려요!',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // "레시피 추천 받기" 버튼 (비로그인 사용자도 이용 가능)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RecipeRecommendScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryColor,
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
      appBar: CustomAppBar(
        onNotificationTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationScreen(),
            ),
          );
        },
      ),
      drawer: const CustomDrawer(),
      body: _buildCurrentScreen(),
      bottomNavigationBar: CustomFooter(
        currentIndex: _currentIndex,
        onTap: (index) => _onFooterTap(index, authProvider),
      ),
    );
  }
}
