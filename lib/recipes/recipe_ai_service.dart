import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'recipe_model.dart';

// ★ 이미 한 번 생성했는지 체크 (중복 호출 방지용 최소 가드)
bool _hasGeneratedOnce = false;

// 1. 목록용 프롬프트 (최대한 단순화)
String buildRecipePrompt({required List<String> ingredients, String? keyword}) {
  final keywordContext = (keyword != null && keyword.isNotEmpty)
      ? "'$keyword' 스타일이나 컨셉, 상황에 맞춰서"
      : "재료와 가장 잘 어울리는 대중적인 방식으로";

  return '''
반드시 다음 형식을 따르는 JSON 리스트만 출력하라.
[조건]
1. 재료: ${ingredients.join(', ')} 
2. 목표: $keywordContext 레시피 3개를 제안하라.
3. 규칙: 레시피 3개, "과정"은 1문장 요약 후 "..." 붙임.
4. 출력 형식: [{"요리 제목":"제목","재료":[{"이름":"재료","용량":"양"}],"과정":["요약..."]}]
''';
}

// 2. 목록 생성 함수
Future<List<RecipeModel>> generateRecipes({
  required List<String> ingredients,
  String? keyword,
}) async {
  // ★ 이미 한 번 성공했다면 재호출 차단
  if (_hasGeneratedOnce) {
    print("이미 레시피 생성됨 - API 재호출 차단");
    return [];
  }

  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
  final prompt = buildRecipePrompt(ingredients: ingredients, keyword: keyword);
  final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey');

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.5,
          "responseMimeType": "application/json" // 이 줄을 추가하면 훨씬 안정적
        }
      }),
    );

    if (response.statusCode != 200) {
      print("API 에러 발생: ${response.statusCode}");
      print("응답 body: ${response.body}");
      return [];
    }

    final decodedResponse = jsonDecode(response.body);

    // API 응답 구조 안전하게 추출
    final candidates = decodedResponse['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      print("candidates 없음");
      return [];
    }

    // ★ parts 전체 text를 합쳐서 사용
    final parts = candidates[0]['content']['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      print("parts 없음");
      return [];
    }

    final responseText = parts
        .map((p) => p['text']?.toString() ?? '')
        .join('\n')
        .trim();

    // JSON 정제 및 복구
    String cleaned = _forceCleanJson(responseText);

    final List<dynamic> jsonList = jsonDecode(cleaned);

    // ★ 여기까지 성공했으면 1회 생성 완료로 간주
    _hasGeneratedOnce = true;

    return jsonList
        .map((e) =>
        RecipeModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
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

  final ingredientsStr = ingredients
      .whereType<Map>()
      .map((e) => e['이름']?.toString() ?? '')
      .where((s) => s.isNotEmpty)
      .join(', ');

  final prompt = '''
$title 레시피를 완성된 형태로 요약해줘.
재료: $ingredientsStr

[필수 조건]
1. 조리 순서를 1번부터 최대 5번까지만 작성하라.
2. **중요**: 각 문장은 반드시 완전한 문장으로 끝맺음하라. (예: ~한다, ~하세요)
3. 서론이나 마무리 인사 없이 바로 본론만 리스트로 출력하라.
4. 설명이 길어지면 핵심 단어 위주로 요약하되 내용은 끝까지 전달하라.
''';

  final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey');

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.5,
          "maxOutputTokens": 800
        }
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // ★ parts 전체를 안전하게 합침
      final candidates = decoded['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception("candidates 비어있음");
      }

      final parts = candidates[0]['content']['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception("parts 비어있음");
      }

      final fullText = parts
          .map((p) => p['text']?.toString() ?? '')
          .join('\n')
          .trim();

      // 줄바꿈으로 나누고 너무 짧은 줄은 버림
      return fullText
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.length > 2)
          .toList();
    }
  } catch (e) {
    print("상세 로드 실패: $e");
  }

  return ["레시피 전문을 불러오지 못했습니다. 다시 시도해주세요."];
}
