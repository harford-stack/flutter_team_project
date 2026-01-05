import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../common/app_colors.dart';
import '../common/custom_appbar.dart';
import '../common/custom_footer.dart';
import '../common/custom_drawer.dart';
import '../ingredients/user_ingredient_regist.dart';
import '../ingredients/user_refrigerator.dart';
import '../community/screens/community_list_screen.dart';
// import '../community/widgets/community_list_widget.dart';
import 'auth_provider.dart';
import 'login_screen.dart';
import 'recipe_option_screen.dart';
import '../notifications/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentSlideIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex; // initialIndex로 초기화
  }

  String _getAppbarTitle(int index){
    switch(index){
      case 0 :
        return '홈';
      case 1 : 
        return '내 재료';
      case 2 :
        return '커뮤니티';
      default : 
        return '어플 이름';
    }
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

    // "내 냉장고"는 독립 화면으로 이동
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const UserRefrigerator(),
        ),
      );
      return;
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
        // "내 냉장고"는 푸터 클릭 시 독립 화면으로 이동하므로 여기서는 빈 화면 또는 다른 화면 표시
        return _buildHomeContent();
      case 2:
        return const CommunityListScreen(showAppBarAndFooter: false);
        // return const CommunityListWidget();
        return _buildHomeContent();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildSlideItem(int index) {
    switch (index) {
      case 0:
        // 첫 번째 슬라이드: 이미지와 텍스트
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/image_slide1.png',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '사진 촬영 또는 사진 선택으로\n다양한 레시피 추천 받기',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      case 1:
        // 두 번째 슬라이드: 이미지와 텍스트 (이미지 오른쪽)
        return Container(
          color: Colors.white,
          child: Row(
            children: [
              // 왼쪽에 텍스트
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      '간단한 터치로\n재료 추가 및 삭제',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ),
              // 오른쪽에 정사각형 이미지
              Image.asset(
                'assets/image_slide2.PNG',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ],
          ),
        );
      case 2:
        // 세 번째 슬라이드: 이미지와 텍스트 (이미지 오른쪽)
        return Container(
          color: Colors.white,
          child: Row(
            children: [
              // 왼쪽에 텍스트
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      '커뮤니티에서\n서로 레시피 공유',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ),
              // 오른쪽에 정사각형 이미지
              Image.asset(
                'assets/image_slide3.PNG',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHomeContent() {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Container(
      color: AppColors.backgroundColor,
      child: Column(
        children: [
          // 앱바 아래 간격
          const SizedBox(height: 16),
          // 이미지 슬라이드 (둥근 모서리, 좌우 여백)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    CarouselSlider(
                      carouselController: _carouselController,
                      options: CarouselOptions(
                        height: 250,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 4),
                        autoPlayAnimationDuration: const Duration(milliseconds: 800),
                        autoPlayCurve: Curves.fastOutSlowIn,
                        enlargeCenterPage: false,
                        viewportFraction: 1.0,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentSlideIndex = index;
                          });
                        },
                      ),
                      items: List.generate(3, (index) {
                        return Builder(
                          builder: (BuildContext context) {
                            return _buildSlideItem(index);
                          },
                        );
                      }),
                    ),
                    // 슬라이드 인디케이터 (오른쪽 상단)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentSlideIndex + 1}/3',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 슬라이더 아래 간격
          const SizedBox(height: 24),
          // 나머지 콘텐츠 (스크롤 가능)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 둥근 모서리 흰색 배경 컨테이너
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('지금 바로 레시피 추천을 받아보세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),),
                        const SizedBox(height: 24),
                        // "레시피 추천 받기" 버튼 (비로그인 사용자도 이용 가능)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RecipeOptionScreen(),
                              ),
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
                        // "내 재료 보러 가기" 버튼 (로그인 상태일 때만 표시)
                        if (authProvider.isAuthenticated) ...[
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const UserRefrigerator(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              side: BorderSide(color: AppColors.primaryColor, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '내 재료 보러 가기',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
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
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        appName: _getAppbarTitle(_currentIndex),
        customTitle: _currentIndex == 0
            ? const Text(
                'ShakeCook',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
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
