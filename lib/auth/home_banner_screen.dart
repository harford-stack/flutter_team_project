// 홈 > 겨울 추천 레시피 배너 클릭 시 이동된 화면

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/app_colors.dart';
import '../common/custom_appbar.dart';
import '../common/custom_drawer.dart';
import '../common/custom_footer.dart';
import '../community/screens/community_list_screen.dart';
import '../ingredients/user_refrigerator.dart';
import 'auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class HomeBannerScreen extends StatelessWidget {
  const HomeBannerScreen({super.key});

  final int _currentIndex = 0;

  void _onFooterTap(BuildContext context, int index, AuthProvider authProvider) {
    if (index == 1 || index == 2) {
      if (!authProvider.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 필요한 메뉴입니다.'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }
    }

    if (index == 2) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const CommunityListScreen(showAppBarAndFooter: true),
        ),
            (route) => false,
      );
      return;
    }

    if (index == 1) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const UserRefrigerator()),
            (route) => false,
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomeScreen(initialIndex: index)),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // 이미지 경로 리스트
    final List<String> imagePaths = [
      'assets/banner_recipe/1-1.png',
      'assets/banner_recipe/1-3.png',
      'assets/banner_recipe/2-1.png',
      'assets/banner_recipe/3-1.png',
      'assets/banner_recipe/4-1.png',
      'assets/banner_recipe/5.png',
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: const CustomAppBar(
        appName: "겨울 추천 레시피",
      ),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(imagePaths.length, (index) {
            Widget currentImage = Image.asset(
              imagePaths[index],
              fit: BoxFit.fitWidth,
              gaplessPlayback: true,
            );

            // ★ 2번 사진(index 1)의 상단에만 흐릿한 마스크 적용
            // if (index == 2) {
            //   return ShaderMask(
            //     shaderCallback: (rect) {
            //       return const LinearGradient(
            //         begin: Alignment.topCenter,    // 위에서부터
            //         end: Alignment.bottomCenter, // 아래로
            //         colors: [
            //           Colors.transparent, // 상단은 투명하게 (흐릿하게)
            //           Colors.white,       // 아래로 올수록 선명하게
            //         ],
            //         stops: [0.0, 0.15], // 0%부터 15% 지점까지만 흐릿하게 처리
            //       ).createShader(rect);
            //     },
            //     blendMode: BlendMode.dstIn, // 마스크 방식 설정
            //     child: currentImage,
            //   );
            // }

            return currentImage;
          }),
        ),
      ),
      bottomNavigationBar: CustomFooter(
        currentIndex: _currentIndex,
        onTap: (index) => _onFooterTap(context, index, authProvider),
      ),
    );
  }
}