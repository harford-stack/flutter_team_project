import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../common/app_colors.dart';
import '../common/custom_appbar.dart';
import '../common/custom_drawer.dart';
import '../common/custom_footer.dart';
import '../ingredients/select_screen.dart';
import '../ingredients/image_confirm.dart';
import '../ingredients/user_refrigerator.dart';
import 'home_screen.dart';

/// 레시피 추천 옵션 선택 화면
class RecipeOptionScreen extends StatefulWidget {
  const RecipeOptionScreen({super.key});

  @override
  State<RecipeOptionScreen> createState() => _RecipeOptionScreenState();
}

class _RecipeOptionScreenState extends State<RecipeOptionScreen> {
  final ImagePicker _picker = ImagePicker();

  // 사진 촬영 로직
  Future<void> _pickFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      if (mounted) {
        Navigator.pop(context); // Bottom Sheet 닫기
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageConfirm(imageFile: imageFile),
          ),
        );
      }
    }
  }

  // 갤러리 선택 로직
  Future<void> _pickFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      if (mounted) {
        Navigator.pop(context); // Bottom Sheet 닫기
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageConfirm(imageFile: imageFile),
          ),
        );
      }
    }
  }

  // 이미지 선택 바텀시트
  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '사진 선택',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _pickFromCamera,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/icon/icon_camera.png',
                                width: 20,
                                height: 20,
                                color: AppColors.textWhite,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '사진 촬영',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textWhite,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _pickFromGallery,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/icon/icon_picture.png',
                                width: 20,
                                height: 20,
                                color: AppColors.textWhite,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '이미지 선택',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textWhite,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        appName: '레시피 추천',
      ),
      drawer: const CustomDrawer(),
      backgroundColor: AppColors.backgroundColor,
      body: Container(
        color: AppColors.backgroundColor,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 앱바 아래 간격
              const SizedBox(height: 16),
              // 추천 이미지 (둥근 모서리, 좌우 여백)
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
                    child: Image.asset(
                      'assets/image_recipe.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // 이미지 아래 간격
              const SizedBox(height: 24),
              // 아이콘과 텍스트 박스 영역
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
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
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 간단 야식도!
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icon/icon_option1.png',
                              width: 40,
                              height: 40,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '간단 야식도!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 구분선
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.grey[300],
                      ),
                      // 캠핑 음식도!
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icon/icon_option2.png',
                              width: 40,
                              height: 40,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '캠핑 음식도!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 구분선
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.grey[300],
                      ),
                      // 도시락 메뉴도!
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icon/icon_option3.png',
                              width: 40,
                              height: 40,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '도시락 메뉴도!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 나머지 콘텐츠
              Padding(
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
                          const Text(
                            '레시피 추천 방법을 선택하세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 버튼 2개 가로로 나란히 배치 (실시간 추천 받기 대신 삽입)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _showImagePickerBottomSheet,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
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
                                    textAlign: TextAlign.center,
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
                                    backgroundColor: AppColors.primaryColor,
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
                          const SizedBox(height: 16),
                          // "내 냉장고 재료로 추천 받기" 버튼
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const UserRefrigerator(
                                    isForRecommendation: true,
                                    fromRecipeOption: true,
                                  ),
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
                              '내 냉장고 재료로 추천 받기',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomFooter(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
                  (route) => false,
            );
          } else if (index == 1) {
            // "내 냉장고"는 독립 화면으로 이동
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const UserRefrigerator(),
              ),
                  (route) => false,
            );
          } else if (index == 2) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(initialIndex: 2),
              ),
                  (route) => false,
            );
          }
        },
      ),
    );
  }
}