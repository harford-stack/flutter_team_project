// AI가 생성한 레시피 내용 관련 모델 파일

class RecipeModel {
  final String title;
  final List<Map<String, String>> ingredients;
  String description;   // 목록 카드용 요약 (업뎃 가능하도록 final 없앰)
  List<String> instructions;   // 상세레시피 = 전체 조리 과정 (리스트) (업뎃 가능하도록 final 없앰)

  // ★ 북마크 상태 변수 (상태가 변해야 하므로 final 아님)
  bool isBookmarked;

  RecipeModel({
    required this.title,
    required this.ingredients,
    required this.description,
    required this.instructions,
    this.isBookmarked = false, // 기본값은 false
  });

  // -----------------------------------------------------------
  // 1. Firestore에 저장하기 위한 Map 변환 메서드
  // -----------------------------------------------------------
  Map<String, dynamic> toFirestore() {
    return {
      "title": title,
      "ingredient": ingredients, // List<Map<String, String>>
      "step": instructions,      // List<String>
      "cdate": DateTime.now(),   // 생성일 (현재 시간)
    };
  }

  // -----------------------------------------------------------
  // 2. Firestore에서 가져온 데이터를 모델로 변환하는 생성자 (통역사 역할)
  // -----------------------------------------------------------
  factory RecipeModel.fromFirestore(Map<String, dynamic> doc) {
    // 'step' 리스트 가져오기
    final List<String> steps = List<String>.from(doc['step'] ?? []);

    return RecipeModel(
      title: doc['title'] ?? '제목 없음',
      ingredients: (doc['ingredient'] as List? ?? [])
          .map<Map<String, String>>((i) => {
        "이름": i["이름"]?.toString() ?? "",
        "용량": i["용량"]?.toString() ?? "",
      })
          .toList(),
      // 첫 번째 조리 과정을 요약(description)으로 사용
      description: steps.isNotEmpty ? steps.first : "맛있는 레시피를 확인해보세요!",
      instructions: steps,
      // DB(보관함)에서 가져온 데이터는 이미 북마크된 것이므로 true 설정
      isBookmarked: true,
    );
  }

  // -----------------------------------------------------------
  // 3. AI 응답(JSON)에서 모델로 변환하는 생성자
  // -----------------------------------------------------------
  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final List<String> steps = List<String>.from(json["과정"] ?? []);

    return RecipeModel(
      title: json["요리 제목"] ?? "제목 없음",
      ingredients: (json["재료"] as List? ?? [])
          .map<Map<String, String>>((i) => {
        "이름": i["이름"]?.toString() ?? "",
        "용량": i["용량"]?.toString() ?? "",
      })
          .toList(),
      description: steps.isNotEmpty ? steps.first : "맛있는 레시피를 확인해보세요!",
      instructions: steps,
      isBookmarked: json["isBookmarked"] ?? false,
    );
  }
}