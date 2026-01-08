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
import 'home_banner_screen.dart';
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

  // 현재 탭 인덱스에 따라 AppBar 제목을 반환하는 함수
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

  // 현재 선택된 탭에 따라 화면을 빌드하는 함수
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

  // 슬라이드 인덱스에 따라 슬라이드 아이템을 빌드하는 함수
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
            // 세련된 느낌을 위해 오른쪽 하단 위주로 어두워지는 그라데이션
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // 텍스트를 오른쪽 하단에 배치
            Positioned(
              right: 24, // 오른쪽 여백
              bottom: 30, // 하단 여백
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end, // 텍스트 오른쪽 정렬
                children: [
                  Text(
                    '사진 촬영 또는 사진 선택으로',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4), // 줄 간격 살짝 띄움
                  Text(
                    '다양한 레시피 추천 받기',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  // 하단에 엣지를 더해주는 포인트 라인 (선택 사항)
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 3,
                    color: AppColors.primaryColor, // 앱의 메인 컬러로 포인트
                  ),
                ],
              ),
            ),
          ],
        );
      case 1:
      // 두 번째 슬라이드: 이미지와 텍스트 (이미지 오른쪽)
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/image_slide2.JPG',
              fit: BoxFit.cover,
            ),
            // 왼쪽 하단 텍스트 가독성을 위해 그라데이션 방향 수정 (오른쪽 상단 -> 왼쪽 하단)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // 텍스트를 왼쪽 하단에 배치
            Positioned(
              left: 24, // 왼쪽 여백
              bottom: 40, // 하단 여백을 조금 더 줌
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 텍스트 왼쪽 정렬
                children: [
                  Text(
                    '간단한 터치로',
                    style: TextStyle(
                      fontSize: 27, // 더 크게 키움
                      fontWeight: FontWeight.w800, // 더 굵게 강조
                      color: Colors.white,
                      letterSpacing: -1.0, // 글자가 커진 만큼 자간을 더 좁혀 세련미 추가
                      height: 1.2,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 3),
                          blurRadius: 12,
                          color: Colors.black.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6), // 줄 간격 살짝 조정
                  Text(
                    '재료 추가 및 삭제',
                    style: TextStyle(
                      fontSize: 27, // 동일하게 크게
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1.0,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 3),
                          blurRadius: 12,
                          color: Colors.black.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                  // 하단 포인트 라인도 왼쪽으로 정렬
                  const SizedBox(height: 16),
                  Container(
                    width: 50, // 글씨가 커진 만큼 라인도 살짝 길게
                    height: 4,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ],
        );
      case 2:
      // 세 번째 슬라이드: 이미지와 텍스트 (이미지 오른쪽 => 꽉 채움 변경)
        return Stack(
          fit: StackFit.expand,
          children: [
            // 배경 이미지 꽉 채우기
            Image.asset(
              'assets/image_slide3_1.JPG',
              fit: BoxFit.cover,
            ),
            // 상단 텍스트 가독성을 위해 위쪽이 더 어두운 그라데이션 적용
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
            ),
            // 왼쪽 상단에서 살짝 내려온 위치에 배치
            Positioned(
              top: 50,  // 상단에서 50만큼 내려옴
              left: 24, // 왼쪽 여백
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 포인트 라인을 텍스트 위로 올려서 상단 배치의 안정감을 줌
                  Container(
                    width: 40,
                    height: 4,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '레시피를 공유하고',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 2),
                          blurRadius: 10,
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '자유롭게 소통해보세요',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 2),
                          //blurRadius: 10,
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // 작은 음식 카드 위젯 헬퍼 함수 추가
  Widget _buildSmallFoodCard(String imagePath) {
    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 3, // 좌우 패딩 및 간격 고려
      height: (MediaQuery.of(context).size.width - 64) / 3, // 정사각형
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // 홈 화면의 메인 콘텐츠를 빌드하는 함수
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
          const SizedBox(height: 20),

          // 추가된 음식 이미지 3개 영역 => 배너로 변경
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeBannerScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16), // 클릭 피드백(물결) 범위 제한
              child: Column(
                children: [
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     _buildSmallFoodCard('assets/homeFood1.jpg'),
                  //     _buildSmallFoodCard('assets/homeFood2.JPG'),
                  //     _buildSmallFoodCard('assets/homeFood3.jpg'),
                  //   ],
                  // ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16), // 모든 모서리를 16만큼 둥글게
                    child: Image.asset(
                      "assets/home_recipe_rec.jpg",
                      height: 140,        // 원하는 세로 길이
                      width: double.infinity, // 가로를 꽉 채우고 싶을 때
                      fit: BoxFit.cover,  // 이미지가 영역에 꽉 차도록 설정
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

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
                  const SizedBox(height: 20),
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
          'ShakeCook!',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Hakgyoansim Dunggeunmiso B',
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