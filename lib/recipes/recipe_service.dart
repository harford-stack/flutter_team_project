// DB 저장하는 함수 작성 위한 파일

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'recipe_model.dart';

class RecipeService {
  // Firestore 인스턴스 가져오기
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // 현재 로그인한 사용자 정보 가져오기
  final User? _user = FirebaseAuth.instance.currentUser;

  // 1. 레시피를 UserHistory 하위 컬렉션에 저장하는 함수
  Future<void> saveRecipeToHistory(RecipeModel recipe) async {
    try {
      if (_user == null) {
        print("로그인된 사용자가 없습니다.");
        return;
      }

      // 저장 경로: users -> {사용자UID} -> UserHistory -> {자동생성문서ID}
      await _db
          .collection('users')
          .doc(_user.uid)
          .collection('UserHistory')
          .add(recipe.toFirestore());

      print("DB 저장 성공: ${recipe.title}");
    } catch (e) {
      print("DB 저장 실패: $e");
      rethrow;
    }
  }

  // 2. 저장된 레시피 목록 가져오기 (Future 방식) - ★ 이 부분이 있어야 빨간 줄이 사라집니다!
  Future<List<RecipeModel>> getSavedRecipes() async {
    try {
      if (_user == null) {
        print("로그인된 사용자가 없습니다.");
        return [];
      }

      // 사용자의 UserHistory 컬렉션에서 'cdate' 기준 최신순으로 가져오기
      final snapshot = await _db
          .collection('users')
          .doc(_user.uid)
          .collection('UserHistory')
          .orderBy('cdate', descending: true)
          .get();

      // 가져온 문서들을 RecipeModel 객체 리스트로 변환
      return snapshot.docs.map((doc) {
        return RecipeModel.fromFirestore(doc.data());
      }).toList();
    } catch (e) {
      print("목록 불러오기 실패: $e");
      return [];
    }
  }

  // 북마크 해제 및 DB 삭제 함수
  Future<void> deleteRecipeFromHistory(String title) async {
    try {
      if (_user == null) return;

      // 제목이 일치하는 문서를 찾아서 가져오기
      final snapshot = await _db
          .collection('users')
          .doc(_user.uid)
          .collection('UserHistory')
          .where('title', isEqualTo: title)
          .get();

      // 찾은 문서들을 반복하며 삭제 (보통 1개임)
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print("DB 삭제 성공: $title");
    } catch (e) {
      print("DB 삭제 실패: $e");
    }
  }





}