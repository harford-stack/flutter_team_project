// Firestore 재료 목록 정리 스크립트
// 1. 중복 재료 삭제
// 2. 일반적인 재료만 남기기

import 'package:cloud_firestore/cloud_firestore.dart';

class CleanupIngredientsScript {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 일반적인 재료 목록 (일반 가정에서 자주 사용하는 재료만)
  final Map<String, List<String>> commonIngredients = {
    '채소': [
      '양파', '마늘', '생강', '대파', '쪽파', '상추', '배추', '양배추', '브로콜리',
      '시금치', '부추', '미나리', '깻잎', '오이', '호박', '애호박', '가지', '토마토', '방울토마토',
      '파프리카', '피망', '고추', '청양고추', '당근', '무', '열무', '고구마', '감자',
      '콩나물', '숙주나물', '팽이버섯', '표고버섯', '새송이버섯', '느타리버섯', '버섯',
      '옥수수', '완두콩', '두부',
    ],
    '과일': [
      '사과', '배', '복숭아', '체리', '딸기', '포도', '수박', '참외', '멜론',
      '오렌지', '귤', '레몬', '바나나', '키위', '파인애플', '망고',
      '대추', '감', '밤', '호두', '땅콩', '아몬드',
    ],
    '육류': [
      '소 등심', '소 안심', '소 갈비살', '돼지 목살', '삼겹살', '돼지갈비', '돼지 다리살',
      '닭가슴살', '닭다리', '닭봉', '오리고기',
    ],
    '해산물': [
      '고등어', '꽁치', '삼치', '멸치', '연어', '참치', '새우',
      '게','오징어', '문어', '주꾸미', '낙지',
      '전복', '바지락', '홍합', '굴', '미역', '다시마', '김',
    ],
    '유제품/계란': [
      '우유', '두유', '요구르트', '치즈', '버터', '생크림',
      '계란',
    ],
    '곡물/면류': [
      '쌀', '현미','소면', '라면', '파스타면',
      '떡','식빵', '밀가루',
    ],
    '가공식품': [
      '햄', '소시지', '베이컨', '두부', '김치',
    ],
    '기타': [
      '식초', '레몬즙', '다시마육수', '멸치육수',
      '된장', '고추장', '간장', '올리브오일', '식용유', '참기름',
      '설탕', '소금', '후추', '고춧가루',
    ],
  };

  // 1. 중복 재료 찾기 및 삭제
  Future<void> removeDuplicates() async {
    try {
      print('=== 중복 재료 찾기 시작 ===');
      
      final ingredientsCollection = _firestore.collection('ingredients');
      final snapshot = await ingredientsCollection.get();
      
      // 이름 기준으로 그룹화
      final Map<String, List<DocumentSnapshot>> nameGroups = {};
      
      for (var doc in snapshot.docs) {
        final name = doc['name'] as String;
        if (!nameGroups.containsKey(name)) {
          nameGroups[name] = [];
        }
        nameGroups[name]!.add(doc);
      }
      
      int deletedCount = 0;
      int keptCount = 0;
      
      // 중복된 재료 처리
      for (var entry in nameGroups.entries) {
        final name = entry.key;
        final docs = entry.value;
        
        if (docs.length > 1) {
          // 첫 번째 문서는 유지, 나머지는 삭제
          print('중복 발견: $name (${docs.length}개)');
          keptCount++;
          
          for (int i = 1; i < docs.length; i++) {
            await docs[i].reference.delete();
            print('  삭제: ${docs[i].id}');
            deletedCount++;
          }
        } else {
          keptCount++;
        }
      }
      
      print('\n=== 중복 재료 삭제 완료 ===');
      print('유지된 재료: $keptCount개');
      print('삭제된 재료: $deletedCount개');
    } catch (e) {
      print('에러 발생: $e');
    }
  }

  // 2. 일반적인 재료만 남기고 나머지 삭제
  Future<void> keepOnlyCommonIngredients() async {
    try {
      print('=== 일반 재료만 남기기 시작 ===');
      
      final ingredientsCollection = _firestore.collection('ingredients');
      final snapshot = await ingredientsCollection.get();
      
      // 일반 재료 목록을 Set으로 변환 (빠른 검색용)
      final Set<String> commonIngredientSet = {};
      for (var category in commonIngredients.values) {
        commonIngredientSet.addAll(category);
      }
      
      int deletedCount = 0;
      int keptCount = 0;
      final List<String> deletedNames = [];
      
      // 모든 재료를 확인하고 일반 재료가 아닌 것 삭제
      for (var doc in snapshot.docs) {
        final name = doc['name'] as String;
        
        if (commonIngredientSet.contains(name)) {
          keptCount++;
        } else {
          await doc.reference.delete();
          deletedNames.add(name);
          deletedCount++;
        }
      }
      
      print('\n=== 일반 재료만 남기기 완료 ===');
      print('유지된 재료: $keptCount개');
      print('삭제된 재료: $deletedCount개');
      print('\n삭제된 재료 목록:');
      for (var name in deletedNames.take(50)) { // 최대 50개만 출력
        print('  - $name');
      }
      if (deletedNames.length > 50) {
        print('  ... 외 ${deletedNames.length - 50}개');
      }
    } catch (e) {
      print('에러 발생: $e');
    }
  }

  // 3. 일반 재료만 추가 (기존 재료 모두 삭제 후 추가)
  Future<void> replaceWithCommonIngredients() async {
    try {
      print('=== 재료 목록 전체 교체 시작 ===');
      
      final ingredientsCollection = _firestore.collection('ingredients');
      
      // 1단계: 기존 재료 모두 삭제
      print('1단계: 기존 재료 삭제 중...');
      final snapshot = await ingredientsCollection.get();
      final batch = _firestore.batch();
      
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('  삭제 완료: ${snapshot.docs.length}개');
      
      // 2단계: 일반 재료 추가
      print('2단계: 일반 재료 추가 중...');
      int addedCount = 0;
      
      for (var categoryEntry in commonIngredients.entries) {
        final category = categoryEntry.key;
        final ingredients = categoryEntry.value;
        
        for (var ingredientName in ingredients) {
          await ingredientsCollection.add({
            'name': ingredientName,
            'category': category,
            'createdAt': FieldValue.serverTimestamp(),
          });
          addedCount++;
        }
      }
      
      print('\n=== 재료 목록 교체 완료 ===');
      print('추가된 재료: $addedCount개');
      print('카테고리 수: ${commonIngredients.keys.length}개');
    } catch (e) {
      print('에러 발생: $e');
    }
  }

  // 4. 통합 실행 (중복 제거 + 일반 재료만 남기기)
  Future<void> cleanupAll() async {
    print('=== 재료 목록 정리 시작 ===\n');
    
    // 1단계: 중복 제거
    await removeDuplicates();
    print('\n');
    
    // 2단계: 일반 재료만 남기기
    await keepOnlyCommonIngredients();
    
    print('\n=== 재료 목록 정리 완료 ===');
  }
}

