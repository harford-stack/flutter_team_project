import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'recipe_model.dart';

// 1. 목록용 프롬프트 (최대한 단순화)
String buildRecipePrompt({required List<String> ingredients, String? keyword}) {
  return '''
JSON 리스트만 출력하라. 
재료: ${ingredients.join(', ')} / 키워드: ${keyword ?? '없음'}
규칙: 레시피 3개, "과정"은 1문장 요약 후 "..." 붙임.
형식: [{"요리 제목":"제목","재료":[{"이름":"재료","용량":"양"}],"과정":["요약..."]}]
''';
}

// 2. 목록 생성 함수
Future<List<RecipeModel>> generateRecipes({
  required List<String> ingredients,
  String? keyword,
}) async {
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
  final prompt = buildRecipePrompt(ingredients: ingredients, keyword: keyword);
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey');

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.5}
      }),
    );

    if (response.statusCode != 200) {
      print("API 에러 발생: ${response.statusCode}");
      return [];
    }

    final decodedResponse = jsonDecode(response.body);
    // API 응답 구조 안전하게 추출
    final candidates = decodedResponse['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return [];

    String responseText = candidates[0]['content']['parts'][0]['text'] ?? '';

    // JSON 정제 및 복구
    String cleaned = _forceCleanJson(responseText);

    final List<dynamic> jsonList = jsonDecode(cleaned);
    return jsonList.map((e) => RecipeModel.fromJson(Map<String, dynamic>.from(e))).toList();

  } catch (e) {
    print("목록 로드 실패 상세: $e");
    return [];
  }
}

// ★ 잘린 JSON을 어떻게든 살려내는 로직
String _forceCleanJson(String input) {
  String text = input.replaceAll(RegExp(r'```json|```'), '').trim();
  int start = text.indexOf('[');
  if (start == -1) return "[]";
  text = text.substring(start);

  // 닫는 대괄호가 없을 때 마지막 '}'를 찾아 강제로 닫기
  if (!text.endsWith(']')) {
    int lastBrace = text.lastIndexOf('}');
    if (lastBrace != -1) {
      text = text.substring(0, lastBrace + 1) + ']';
    } else {
      text += ']';
    }
  }
  // 문법 오류 방지 (따옴표 짝수화)
  if ('"'.allMatches(text).length % 2 != 0) text += '"';
  return text.replaceAll(',]', ']').replaceAll(',}', '}');
}

// 3. 상세 페이지 전문 로드 함수
// ★ 상세 조리 과정을 더 빠르게 가져오도록 최적화
Future<List<String>> getFullInstructions({
  required String title,
  required List<dynamic> ingredients,
}) async {
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
  final ingredientsStr = ingredients.map((e) => "${e['이름']}").join(', ');

  final prompt = '''
$title 레시피를 완성된 형태로 요약해줘.
재료: $ingredientsStr

[필수 조건]
1. 조리 순서를 1번부터 최대 5번까지만 작성하라.
2. **중요**: 각 문장은 반드시 완전한 문장으로 끝맺음하라. (예: ~한다, ~하세요)
3. 서론이나 마무리 인사 없이 바로 본론만 리스트로 출력하라.
4. 설명이 길어지면 핵심 단어 위주로 요약하되 내용은 끝까지 전달하라.
''';

  final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey');

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
          "temperature": 0.5,      // 약간의 창의성을 허용해 문장을 자연스럽게 만듦
          "maxOutputTokens": 800   // 잘림 방지를 위해 500에서 800으로 상향
        }
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      String fullText = decoded['candidates'][0]['content']['parts'][0]['text'] ?? '';

      // 줄바꿈으로 나누고 너무 짧은 줄은 버림
      return fullText
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.length > 5)
          .toList();
    }
  } catch (e) {
    print("상세 로드 실패: $e");
  }
  return ["레시피 전문을 불러오지 못했습니다. 다시 시도해주세요."];
}