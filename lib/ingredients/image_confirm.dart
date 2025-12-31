import 'package:flutter/material.dart';
import 'package:flutter_team_project/common/app_colors.dart';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:http/http.dart';

import '../providers/temp_ingre_provider.dart';
import 'package:provider/provider.dart';

import '../recipes/ingreCheck_screen.dart';


class Ingredient {
  final String name;
  final String category;

  Ingredient({
    required this.name,
    required this.category,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String,
      category: json['category'] as String,
    );
  }

  @override
  String toString() {
    return '{name: $name, category: $category}';
  }
}


class ImageConfirm extends StatefulWidget {
  final File imageFile;
  const ImageConfirm({
    super.key,
    required this.imageFile
  });

  @override
  State<ImageConfirm> createState() => _ImageConfirmState();
}

class _ImageConfirmState extends State<ImageConfirm> {
  String _result = '';
  bool _isLoading = false;

  // [추가 부분] 화면 진입 시 데이터 초기화 ---------------------------
  @override
  void initState() {
    super.initState();
  }
  // ------------------------------------------------------------------

  //이미지 분석
  Future<void> _analyzeImage() async {

    // ★ [이동된 부분] -----------------------------------------------
    // 사진 분석 "시작" 시점에서만 Provider 초기화
    final provider = context.read<TempIngredientProvider>();
    provider.clearAll();
    // ---------------------------------------------------------------

    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      // final apiKey = dotenv.env['GEMINI_API_KEY'];
      // if (apiKey == null || apiKey.isEmpty) {
      //   throw Exception('API 키가 설정되지 않았습니다.');
      // }
      //
      // // Gemini 모델 초기화
      // final model = GenerativeModel(
      //   model: 'models/gemini-2.5-flash',
      //   apiKey: apiKey,
      // );
      //
      // // 이미지 파일을 바이트로 읽기
      // final imageBytes = await widget.imageFile.readAsBytes();
      //
      // // 이미지 데이터 생성
      // final imagePart = DataPart('image/jpeg', imageBytes);
      //
      // // 프롬프트와 이미지를 함께 전송
      // final prompt = TextPart(
      //     '이 이미지에 있는 식재료를 객체배열의 형태로 정리해주세요. 조건은 다음과 같습니다.'
      //       '1.가공식품, 곡물/면류, 과일, 유제품/계란, 육류, 채소, 해산물, 기타에 따라 분류할 것'
      //       '1-1.만약 계란이라면 name:계란,category:유제품/계란 같은 형식으로 분류 후 나열하여주세요'
      //       '2.정확히 파악이 되지 않고, 추정만 가능하다면 파악 불가한 재료로 판단 후 목록에서 제외해주세요.'
      //       '2-1.캔이나 병처럼 내용물이 정확하게 파악되지 않는 경우, 목록에서 제외해주세요.'
      //       '2-2.병이나 캔에 들어있는 재료의 경우, (병에 든)같은 부가설명은 덧붙이지 말고, 해당 재료의 이름만 출력해주세요'
      //       // '2-2.파악하기 힘든 재료는 목록에서 제외하였다고 말해주세요.'
      //       '3.객체배열의 이름은 ingredients 로 해주세요.'
      //       '4.객체배열 이전에 출력되는 설명문은 info 라는 이름으로 해주세요.'
      //       '4-1.info의 내용: 이미지에서 파악된 식재료 목록입니다. 파악하기 힘든 재료(병, 캔 안의 내용물 및 불분명한 식품)는 목록에서 제외하였습니다. 파악이 정확하지 않을 수 있으니, 다시 한번 확인해주세요.'
      //       '5.응답은 반드시 JSON만 반환할 것.'
      //       '5-1.```json``` 같은 마크다운 사용 금지.'
      //       // '6.설명 문장의 끝에는 파악이 정확하지 않을 수 있으니, 다시 한번 확인해주세요. 라는 문장을 덧붙여주세요.'
      // );
      // final response = await model.generateContent([
      //   Content.multi([prompt, imagePart])
      // ]);
      //
      // setState(() {
      //   _result = response.text ?? '응답이 없습니다.';
      //   _isLoading = false;
      // });

      // Provider에 사진 추가
      final provider = context.read<TempIngredientProvider>();
      provider.addPhoto(widget.imageFile);

      print('Gemini 응답: $_result');
      // String aiResponse = response.text!;
      //테스트용
      String aiResponse = '{"info": "이미지에서 파악된 식재료 목록입니다. 파악하기 힘든 재료(병, 캔 안의 내용물 및 불분명한 식품)는 목록에서 제외하였습니다. 파악이 정확하지 않을 수 있으니, 다시 한번 확인해주세요.", "ingredients": [{"name": "계란", "category": "유제품/계란"}, {"name": "치즈", "category": "유제품/계란"}, {"name": "토마토", "category": "채소"}, {"name": "레몬", "category": "과일"}, {"name": "청포도", "category": "과일"}, {"name": "당근", "category": "채소"}, {"name": "오렌지", "category": "과일"}]}';

      print('aiResponse: $aiResponse');

      Map<String, dynamic> parseAiJson(String raw) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }

      // final Map<String, dynamic> jsonMap = parseAiJson(aiResponse);
      final Map<String, dynamic> jsonMap = jsonDecode(aiResponse);

      print('jsonMap: $jsonMap');
      final String info = jsonMap['info'] as String;
      print('info: $info');

      //사진으로 파악한 재료의 list화
      //아직 작동확인 안됨
      final List<Ingredient> ingredients =
      (jsonMap['ingredients'] as List)
          .map((e) => Ingredient.fromJson(e))
          .toList();

      // print('ingredients count: ${ingredients.length}');
      print('ingredients: ${ingredients}');

      // [추가 부분] -------------------------------------------------------
      // 1. Ingredient 객체에서 이름(name)만 뽑아서 String 리스트로 만듭니다.
      final List<String> ingredientNames = ingredients.map((e) => e.name).toList();

      // 2. Provider에 재료 이름들을 추가합니다. (info는 현재 저장안됨!)
      provider.addAll(ingredientNames);

      // ★ ↓ 아래 내용은 필요시 주석 풀기
      // (AI 전송 버튼의 로딩 상태를 해제하고 화면에 결과를 보여주려면)
      // setState(() {
      //   _result = info; // AI가 보내준 설명 문구 표시
      //   _isLoading = false; // 로딩 인디케이터 해제
      // });

      // ------------------------------------------------------------------

      // 이후 화면 이동 로직이 필요하다면 여기에 추가 (예: Navigator.push 등)

      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_)=>IngrecheckScreen()
          )
      );

    } catch (e) {
      print('오류 상세: $e');
      setState(() {
        _result = '오류 발생: $e';
        _isLoading = false;
      });
    }
  }

  // Future<void> _transIngredients () {
  //
  // }

  // 사용가능 gemini 버전 조회용
  // Future<void> _listModels() async {
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   try {
  //     final apiKey = dotenv.env['GEMINI_API_KEY'];
  //     if (apiKey == null || apiKey.isEmpty) {
  //       print('API 키가 없습니다.');
  //       return;
  //     }
  //
  //     final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  //     final response = await http.get(url);
  //
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       print('\n=== 사용 가능한 모델 목록 ===');
  //       for (var model in data['models']) {
  //         final methods = model['supportedGenerationMethods'] ?? [];
  //         if (methods.contains('generateContent')) {
  //           print('✓ ${model['name']} - generateContent 지원');
  //         }
  //       }
  //       print('========================\n');
  //     } else {
  //       print('오류: ${response.statusCode} - ${response.body}');
  //     }
  //   } catch (e) {
  //     print('오류: $e');
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이미지 확인'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textWhite,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  widget.imageFile,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _analyzeImage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  "Gemini에게 전송",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              if (_result.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _result,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}