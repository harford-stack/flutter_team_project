// AI가 생성한 레시피 내용 관련 모델 파일
// 임시로 채워둔거라 ai 연결하면서 재확인 예정!

class RecipeModel {
  final String title;
  final List<String> ingredients;
  final String description;   // 목록 카드용 요약
  final String instruction;   // 상세 레시피

  RecipeModel({
    required this.title,
    required this.ingredients,
    required this.description,
    required this.instruction,
  });
}