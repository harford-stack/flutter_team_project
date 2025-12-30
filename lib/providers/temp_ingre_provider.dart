// 레시피 제작을 위한 "재료 목록 임의 보관" 화면
// List<String>에 임의 보관 예정
//     ├─ 카메라 결과 추가
//     ├─ 갤러리 결과 추가
//     ├─ 재료 선택 결과 추가
//     ├─ DB 저장(내 냉장고재료 등록) 버튼 누르면 저장
//     └─ 화면 종료 시 자연 소멸

import 'dart:io';
import 'package:flutter/cupertino.dart';

// ChangeNotifier 기반 Provider는 Widget이 아니라 “상태 객체”
// 그래서 StatefulWidget 또는 StatelessWidget이 등장 x (ui 위젯이 아니므로)

class TempIngredientProvider extends ChangeNotifier {
  // 1. 기존 문자열 재료 (목록에서 선택한 재료) 담는 리스트
  final List<String> _ingredients = [];
  List<String> get ingredients => List.unmodifiable(_ingredients);

  // 2. 사진 전용 리스트
  final List<File> _photos = [];
  List<File> get photos => List.unmodifiable(_photos);

  // 3. 키워드 (사용자 직접 입력)
  String _keyword = "";
  String get keyword => _keyword;


  // 메소드 1) 기존 문자열 재료  ---------------------
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
// ---------------------------------------------


  // 메소드 2) 사진 (UI나 다른 화면에서는 provider.photos로 접근 가능)
  void addPhoto(File photo) {
    _photos.add(photo);
    notifyListeners();
  }

  void addAllPhotos(List<File> photos) {
    _photos.addAll(photos);
    notifyListeners();
  }

  void removePhoto(File photo) {
    _photos.remove(photo);
    notifyListeners();
  }

  void clearPhotos() {
    _photos.clear();
    notifyListeners();
  }

// ---------------------------------------------

  // 메소드 3) 키워드
  void setKeyword(String value) {
    _keyword = value;
    notifyListeners();
  }

  void clearKeyword() {
    _keyword = "";
    notifyListeners();
  }

// ---------------------------------------------
  // 전체 초기화하는 메소드
  void clearIngredients() {
    _ingredients.clear();
    notifyListeners();
  }

  // 전체 초기화
  void clearAll() {
    clearIngredients(); // 재료 리스트 초기화
    clearPhotos();      // 사진 리스트 초기화
    clearKeyword();     // 키워드 초기화
  }

}
