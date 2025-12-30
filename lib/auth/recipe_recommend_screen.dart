import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/app_colors.dart';
import '../common/custom_appbar.dart';
import '../common/custom_footer.dart';
import '../common/custom_drawer.dart';
import '../ingredients/regist_screen.dart';
import '../ingredients/select_screen.dart';
import '../community/screens/community_list_screen.dart';
import 'auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RecipeRecommendScreen extends StatefulWidget {
  const RecipeRecommendScreen({super.key});

  @override
  State<RecipeRecommendScreen> createState() => _RecipeRecommendScreenState();
}

class _RecipeRecommendScreenState extends State<RecipeRecommendScreen> {
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

    // 홈 화면으로 이동하면서 해당 인덱스로 설정
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomeScreen(initialIndex: index),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: const CustomDrawer(),
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // 추천 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/icon_recommend2.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              // 코드로 구현한 추천 방식 선택 섹션
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // 음식 아이콘들
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFoodIcon(Icons.soup_kitchen, '국물'),
                        _buildFoodIcon(Icons.restaurant, '떡볶이'),
                        _buildFoodIcon(Icons.ramen_dining, '비빔국수'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '추천 방식 선택하기',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // 버튼 2개 가로로 나란히 배치
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const Regist(),
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
                        '촬영 또는 앨범 사진',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SelectScreen(),
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
                        '재료 직접 선택',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomFooter(
        currentIndex: _currentIndex,
        onTap: (index) => _onFooterTap(index, authProvider),
      ),
    );
  }

  Widget _buildFoodIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 40,
            color: AppColors.textWhite,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textWhite,
          ),
        ),
      ],
    );
  }
}

