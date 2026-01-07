import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../auth/home_screen.dart';
import '../common/app_colors.dart';
import '../providers/temp_ingre_provider.dart';
import 'recipe_model.dart';
import 'recipe_ai_service.dart';
import 'package:flutter_team_project/common/bookmark_button.dart';
import 'package:flutter_team_project/recipes/recipe_service.dart';
import 'package:provider/provider.dart';

class RecipedetailScreen extends StatefulWidget {
  final RecipeModel recipe;
  final bool isFromSaved; // ★ 저장된 레시피로부터 왔는지 여부 확인하는 변수

  const RecipedetailScreen({
    super.key,
    required this.recipe,
    this.isFromSaved = false, // 기본값 false
  });


  @override
  State<RecipedetailScreen> createState() => _RecipedetailScreenState();
}

class _RecipedetailScreenState extends State<RecipedetailScreen> {
  List<String> _fullInstructions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFullRecipe();
  }

  Future<void> _loadFullRecipe() async {
    // 만약 이미 레시피 단계(instructions)가 존재한다면 AI를 부르지 않음
    // ★ 추가 조건: 목록에서 생성된 요약본(description 대용)이 아닌 실제 전문인 경우에만 스킵
    if (widget.recipe.instructions.isNotEmpty &&
        !widget.recipe.instructions.any((step) => step.contains('...'))) {
      if (mounted) {
        setState(() {
          _fullInstructions = widget.recipe.instructions;
          _isLoading = false; // 로딩바를 즉시 끔
        });
      }
      return; // 함수 종료
    }

    // 데이터가 없을 때만(일회성 생성 시) 기존처럼 AI 호출
    try {
      final result = await getFullInstructions(
        title: widget.recipe.title,
        ingredients: widget.recipe.ingredients,
      );
      if (mounted) {
        setState(() {
          _fullInstructions = result;
          // ★ 모델에도 전문을 저장하여 이후 다시 진입 시 재호출 방지
          widget.recipe.instructions = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fullInstructions = ["레시피를 불러오는 중 오류가 발생했습니다. 다시 시도해주세요."];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 제목 섹션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.recipe.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                // 북마크 공통 위젯 적용
                BookmarkButton(
                  // ★ 레시피 목록 화면에서 바뀐 상태를 그대로 받음
                  isInitialBookmarked: widget.recipe.isBookmarked,
                  size: 28,             // 상세화면에 맞게 크기 키움
                  isTransparent: true,  // 상세화면은 배경 없이 깔끔하게
                  onToggle: (state) async {
                    widget.recipe.isBookmarked = state; // 상세에서 바꿔도 모델에 기록됨

                    if (state) {
                      // ★ 상세 화면에서도 클릭 시 DB 저장!
                      try {
                        await RecipeService().saveRecipeToHistory(widget.recipe);
                        print("상세 화면에서 DB 저장 성공");
                      } catch (e) {
                        print("상세 화면 저장 실패: $e");
                      }
                    } else {
                      // ★ 추가: 북마크 해제 시 DB에서 삭제 로직 연결
                      try {
                        await RecipeService().deleteRecipeFromHistory(widget.recipe.title);
                        print("상세 화면에서 DB 삭제 성공");
                      } catch (e) {
                        print("상세 화면 삭제 실패: $e");
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 25),

            // 2. 재료 섹션 (데이터가 이미 있으므로 바로 보여줌)
            const Text(
              "필요한 재료",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: widget.recipe.ingredients
                  .map((item) => _buildIngredientChip("${item["이름"]} ${item["용량"]}"))
                  .toList(),
            ),
            const SizedBox(height: 35),

            // 3. 상세 레시피 섹션 (이 부분이 핵심!)
            const Text(
              "조리 순서",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 200), // 최소 높이 확보로 덜렁거림 방지
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05), // 너무 진하지 않은 그림자 색상
                    spreadRadius: 2,   // 그림자가 퍼지는 범위
                    blurRadius: 10,    // 그림자의 부드러움 정도
                    offset: const Offset(0, 4), // 그림자 위치 (가로 0, 세로 4 아래로)
                  ),
                ],
                //border: Border.all(color: Colors.grey.shade200),
              ),
              child: _isLoading
                  ? _buildLoadingState() // 로딩 중일 때 보여줄 UI
                  : _buildRecipeList(),  // 로딩 완료 후 보여줄 UI
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),

      // 아래에 '홈으로' 버튼 & 위치 고
      // ★  변수 isFromSaved가 false일 때만 버튼을 보여줌 (
      bottomNavigationBar: widget.isFromSaved ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 중요: 컬럼 크기를 최소화하여 버튼 높이만큼만 차지하게 함
            children: [
              SizedBox(
                width: double.infinity, // 버튼을 가로로 꽉 차게
                height: 55, // 버튼 높이 조절
                child: ElevatedButton(
                  onPressed: () {
                    context.read<TempIngredientProvider>().clearAll();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "홈으로",
                    style: TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "홈으로 이동 시 생성된 레시피는 소멸됩니다.",
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI 컴포넌트 분리 ---

  // 로딩 상태 UI: 사용자가 대기 중임을 인지하고 신뢰감을 갖게 함
  // 로딩 상태 UI에 이미지(또는 GIF) 추가
  Widget _buildLoadingState() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          // 1. 요리 관련 이미지/GIF (인터넷에서 가져오거나 에셋 사용)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/recipe_loading.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.restaurant, size: 50, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          const CupertinoActivityIndicator(radius: 12),
          const SizedBox(height: 15),
          const Text(
            "AI 셰프가 레시피를\n정성껏 작성하고 있어요",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "약 5초 정도 소요될 수 있습니다",
            style: TextStyle(fontSize: 15, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // 레시피 리스트 UI: 깔끔한 단계별 출력
  Widget _buildRecipeList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _fullInstructions.map((step) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 텍스트만 뿌리는 대신 줄간격과 스타일 적용
              Expanded(
                child: Text(
                  step,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.7,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 재료 칩 디자인
  Widget _buildIngredientChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }
}