// 레시피 제작을 위한 "재료 목록 임의 보관" 화면
// List<String>에 임의 보관 예정
//     ├─ 카메라 결과 추가
//     ├─ 갤러리 결과 추가
//     ├─ 재료 선택 결과 추가
//     ├─ DB 저장(내 냉장고재료 등록) 버튼 누르면 저장
//     └─ 화면 종료 시 자연 소멸

import 'package:flutter/cupertino.dart';

// ChangeNotifier 기반 Provider는 Widget이 아니라 “상태 객체”
// 그래서 StatefulWidget 또는 StatelessWidget이 등장 x (ui 위젯이 아니므로)

class TempIngredientProvider extends ChangeNotifier {
  final List<String> _ingredients = [];

  List<String> get ingredients => List.unmodifiable(_ingredients);

  void addIngredient(String ingredient) {
    if (_ingredients.contains(ingredient)) return;
    _ingredients.add(ingredient);
    notifyListeners();
  }

  void addAll(List<String> ingredients) {
    for (final i in ingredients) {
      if (!_ingredients.contains(i)) {
        _ingredients.add(i);
      }
    }
    notifyListeners();
  }

  void removeIngredient(String ingredient) {
    _ingredients.remove(ingredient);
    notifyListeners();
  }

  void clear() {
    _ingredients.clear();
    notifyListeners();
  }
}
