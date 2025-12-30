// AI가 생성한 레시피 내용 관련 모델 파일
// 임시로 채워둔거라 ai 연결하면서 재확인 예정!

class RecipeModel {
  final String title;
  final List<Map<String, String>> ingredients;
  final String description;   // 목록 카드용 요약
  final List<String> instructions;   // 상세레시피 = 전체 조리 과정 (문자열)

  // ★ 1. 북마크 상태 변수 추가 (상태가 변해야 하므로 final을 붙이지 않음)
  bool isBookmarked;

  RecipeModel({
    required this.title,
    required this.ingredients,
    required this.description,
    required this.instructions,
    this.isBookmarked = false, // ★ 2. 생성자에서 기본값을 false로 설정
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final List<String> steps =
    List<String>.from(json["과정"] ?? []);

    return RecipeModel(
      title: json["요리 제목"] ?? "제목 없음",
      ingredients: (json["재료"] as List? ?? [])
          .map<Map<String, String>>((i) => {
        "이름": i["이름"]?.toString() ?? "",
        "용량": i["용량"]?.toString() ?? "",
      })
          .toList(),

      description:
      steps.isNotEmpty ? steps.first : "맛있는 레시피를 확인해보세요!",

      // 🔑 리스트를 하나의 문자열로 합침
      instructions: steps,

      // ★ 3. JSON 데이터에 북마크 정보가 있다면 가져오고, 없으면 false가 기본값이 됩니다.
      isBookmarked: json["isBookmarked"] ?? false,

    );
  }
}
