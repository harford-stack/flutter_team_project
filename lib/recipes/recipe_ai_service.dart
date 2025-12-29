// AI 통해 레시피 생성하는 서비스 파일

// 1. 프롬프트 템플릿 구성 (문자열 함수로 분리)
// 2. AI API 호출 (REST 말고 SDK 사용 예정)
// 3. 결과 파싱
// 4. RecipeModel 3개 반환

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

String buildRecipePrompt({
  required List<String> ingredients,
  String? keyword,
}) {
  return '''
너는 Flutter 앱에서 사용하는 레시피 생성 엔진이다.

[목표]
- 제공된 재료를 이용해 요리 레시피 3개를 생성하라.

[조건]
- 아래 재료 외 추가 재료는 일반 가정용 조미료만 허용:
  소금, 설탕, 간장, 참기름, 후추, 고추장, 된장
- 모든 요리는 사람이 식용 가능한 수준이어야 한다.
- 모든 재료를 반드시 사용할 필요는 없다.
- 레시피 장르 및 종류는 자유다.
${keyword != null ? '- 추가 키워드: "$keyword"를 반드시 반영할 것.' : ''}

[입력 재료]
${ingredients.join(', ')}

[출력 규칙]
- 반드시 JSON 배열(List) 형태로 출력하라.
- JSON 외의 텍스트는 절대 출력하지 마라.
- 코드블록을 사용하지 마라.
- key 이름은 반드시 아래와 같아야 한다:
  - "요리 제목"
  - "재료" : [{ "이름", "용량" }]
  - "과정" : [문자열]

[출력 예시 형식]
[
  {
    "요리 제목": "김치볶음밥",
    "재료": [
      {"이름": "밥", "용량": "1공기"},
      {"이름": "김치", "용량": "한 줌"}
    ],
    "과정": [
      "1. 팬에 기름을 두르고 김치를 볶는다.",
      "2. 밥을 넣고 함께 볶는다.",
      "3. 간장으로 간을 맞춘다."
    ]
  }
]

[불가능한 경우]
- 현실적으로 조리가 불가능하거나 사람이 먹기 힘들다면
아래 형식으로만 출력하라:
{
  "error": true,
  "message": "현실적으로 조리가 불가능한 재료 조합입니다."
}
''';
}


// 서비스 함수: SDK 방식으로 교체
Future<List<dynamic>> generateRecipes({
  required List<String> ingredients,
  String? keyword,
}) async {
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

  // 1. 모델 설정 (Gemini 1.5 Flash 추천)
  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

  final prompt = buildRecipePrompt(
    ingredients: ingredients,
    keyword: keyword,
  );

  // 2. SDK를 통한 호출
  final response = await model.generateContent([Content.text(prompt)]);
  final responseText = response.text ?? "";

  // 3. 파싱
  final decoded = jsonDecode(responseText);

  if (decoded is Map && decoded["error"] == true) {
    throw Exception(decoded["message"]);
  }

  return decoded as List<dynamic>;
}


