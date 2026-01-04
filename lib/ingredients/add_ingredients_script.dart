// Firestore에 재료를 추가하는 스크립트
// 이 파일은 일회성으로 실행하여 재료 데이터를 Firestore에 추가하는 용도입니다.

import 'package:cloud_firestore/cloud_firestore.dart';

class AddIngredientsScript {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 카테고리별 재료 목록 (중복 없이 추가)
  final Map<String, List<String>> ingredientsByCategory = {
    '채소': [
      '양파', '마늘', '생강', '대파', '쪽파', '상추', '배추', '양배추', '브로콜리', '콜리플라워',
      '시금치', '케일', '아욱', '부추', '미나리', '깻잎', '치커리', '적상추', '로메인',
      '오이', '호박', '애호박', '단호박', '박', '가지', '토마토', '방울토마토', '파프리카', '피망',
      '고추', '청양고추', '풋고추', '고춧가루', '당근', '무', '열무', '순무', '비트', '우엉',
      '연근', '도라지', '더덕', '취나물', '고사리', '시래기', '콩나물', '숙주나물', '숙주', '팽이버섯',
      '표고버섯', '새송이버섯', '느타리버섯', '목이버섯', '송이버섯', '버섯', '감자', '고구마', '옥수수',
      '완두콩', '강낭콩', '병아리콩', '렌틸콩', '콩', '두부', '팥', '녹두',
    ],
    '과일': [
      '사과', '배', '복숭아', '자두', '살구', '체리', '딸기', '블루베리', '라즈베리', '블랙베리',
      '포도', '청포도', '거봉', '샤인머스캣', '수박', '참외', '멜론', '오렌지', '귤', '한라봉',
      '레몬', '라임', '자몽', '유자', '석류', '망고', '파인애플', '바나나', '키위',
      '용과', '두리안', '리치', '람부탄', '코코넛', '아보카도', '대추', '감', '곶감', '밤',
      '호두', '땅콩', '아몬드', '캐슈넛', '피스타치오', '마카다미아', '해바라기씨', '호박씨', '참깨', '들깨',
    ],
    '육류': [
      '소고기', '한우', '갈비살', '등심', '안심', '채끝살', '우둔', '설도', '양지', '사태',
      '갈비', '소갈비', 'LA갈비', '불고기용', '국거리', '사골', '우족', '양지머리', '차돌박이', '우삼겹',
      '돼지고기', '목살', '삼겹살', '앞다리살', '뒷다리살', '갈비살', '등심', '안심', '목심', '갈매기살',
      '항정살', '가브리살', '돼지갈비', '돼지불고기', '돼지국거리', '돼지사골', '돼지족발', '돼지껍데기', '돼지머리', '돼지뼈',
      '닭고기', '닭가슴살', '닭다리', '닭날개', '닭봉', '닭발', '닭목', '닭뼈', '닭내장', '닭껍질',
      '오리', '오리고기', '오리훈제', '오리불고기', '오리국거리', '오리뼈', '오리내장', '오리껍질', '오리발', '오리목',
      '양고기', '양갈비', '양다리', '양등심', '양안심', '양목살', '양갈비살', '양불고기', '양국거리', '양뼈',
    ],
    '해산물': [
      '고등어', '꽁치', '삼치', '멸치', '전갱이', '정어리', '청어', '대구', '명태', '동태',
      '연어', '참치', '참치캔', '참치회', '참치스테이크', '참치살', '참치뱃살', '참치목살', '참치등심', '참치안심',
      '광어', '우럭', '도미', '농어', '볼락', '감성돔', '참돔', '돔', '붕어', '잉어',
      '새우', '대하', '중하', '소하', '새우살', '새우머리', '새우껍질', '새우다리', '새우꼬리', '새우내장',
      '게', '꽃게', '대게', '킹크랩', '랍스터', '가재',
      '오징어', '문어', '한치', '주꾸미', '낙지', '쭈꾸미', '오징어다리', '오징어몸통', '오징어머리', '오징어내장',
      '전복', '소라', '고둥', '바지락', '홍합', '관자', '가리비', '키조개', '대합', '조개',
      '굴', '멍게', '해삼', '성게', '말미잘', '해파리', '멸치', '멸치젓', '멸치액젓', '멸치포',
      '미역', '다시마', '김', '파래', '청각', '톳', '해초', '우뭇가사리', '곰피', '매생이',
    ],
    '유제품/계란': [
      '우유', '저지방우유', '무지방우유', '고칼슘우유', '딸기우유', '초코우유', '바나나우유', '두유', '콩우유', '아몬드우유',
      '요구르트', '플레인요구르트', '딸기요구르트', '복숭아요구르트', '블루베리요구르트', '그릭요구르트', '요거트', '요거트드링크', '요거트스무디', '요거트아이스크림',
      '치즈', '모짜렐라치즈', '체다치즈', '고다치즈', '까망베르치즈', '브리치즈', '리코타치즈', '크림치즈', '파마산치즈', '블루치즈',
      '버터', '마가린', '생크림', '휘핑크림', '사워크림', '크림치즈', '리코타치즈', '마스카포네', '코티지치즈', '프로볼로네',
      '계란', '달걀', '메추리알', '오리알', '계란노른자', '계란흰자', '계란가루', '계란물', '계란후라이', '계란찜',
      '아이스크림', '바닐라아이스크림', '초코아이스크림', '딸기아이스크림', '민트초코아이스크림', '카라멜아이스크림', '쿠키앤크림', '스트로베리', '피스타치오', '헤이즐넛',
    ],
    '곡물/면류': [
      '쌀', '현미', '흑미', '찹쌀', '멥쌀', '보리', '밀', '귀리', '퀴노아', '아마씨',
      '국수', '소면', '칼국수', '우동', '라면', '짜파게티', '불닭볶음면', '신라면', '너구리', '안성탕면',
      '스파게티', '파스타', '펜네', '푸실리', '라자냐', '마카로니', '펜네파스타', '푸실리파스타', '라자냐시트', '라비올리',
      '떡', '가래떡', '쌀떡', '찰떡', '인절미', '송편', '백설기', '시루떡', '절편', '경단',
      '만두', '물만두', '군만두', '왕만두', '교자', '샤오롱바오', '딤섬', '하가우', '시우마이', '춘권',
      '빵', '식빵', '바게트', '크로와상', '도넛', '머핀', '베이글', '치아바타', '포카치아', '피자빵',
      '밀가루', '강력분', '중력분', '박력분', '전분', '옥수수전분', '감자전분', '고구마전분', '타피오카전분', '녹말',
    ],
    '가공식품': [
      '햄', '소시지', '베이컨', '프랑크푸르트', '비엔나소시지', '치킨너겟', '치킨텐더', '치킨윙', '치킨스틱', '치킨패티',
      '어묵', '오뎅', '어묵볼', '어묵스틱', '어묵튀김', '어묵국', '어묵볶음', '어묵전', '어묵무침', '어묵샐러드',
      '두부', '연두부', '부침두부', '묵은지', '김치', '배추김치', '깍두기', '총각김치', '열무김치', '나박김치',
      '된장', '고추장', '간장', '양조간장', '진간장', '국간장', '멸치액젓', '새우젓', '게젓', '오징어젓',
      '마요네즈', '케첩', '머스타드', '바베큐소스', '칠리소스', '타바스코', '와사비', '고추냉이', '겨자', '머스타드',
      '올리브오일', '식용유', '참기름', '들기름', '포도씨유', '옥수수기름', '해바라기씨유', '카놀라유', '코코넛오일', '아보카도오일',
      '설탕', '흑설탕', '황설탕', '꿀', '물엿', '올리고당', '시럽', '메이플시럽', '아가베시럽', '스테비아',
      '소금', '천일염', '바다소금', '히말라야핑크솔트', '후추', '후추가루', '고춧가루', '파프리카파우더', '커민', '코리앤더',
    ],
    '기타': [
      '견과류', '땅콩', '아몬드', '호두', '캐슈넛', '피스타치오', '마카다미아', '브라질너트', '피칸', '헤이즐넛',
      '건조과일', '건포도', '건크랜베리', '건블루베리', '건살구', '건자두', '건무화과', '건대추', '건곶감', '건밤',
      '조미료', 'MSG', '다시마육수', '멸치육수', '사골육수', '치킨스톡', '비프스톡', '베지터블스톡', '토마토페이스트', '토마토소스',
      '향신료', '로즈마리', '타임', '오레가노', '바질', '파슬리', '딜', '세이지', '민트', '라벤더',
      '식초', '양조식초', '사과식초', '발사믹식초', '레몬즙', '라임즙', '오렌지즙', '자몽즙', '유자즙', '석류즙',
    ],
  };

  // Firestore에 재료 추가
  Future<void> addIngredients() async {
    try {
      final ingredientsCollection = _firestore.collection('ingredients');
      
      // 기존 재료 목록 가져오기 (중복 체크용)
      final existingSnapshot = await ingredientsCollection.get();
      final existingIngredients = <String>{};
      
      for (var doc in existingSnapshot.docs) {
        final name = doc['name'] as String;
        final category = doc['category'] as String;
        existingIngredients.add('$category:$name');
      }

      int addedCount = 0;
      int skippedCount = 0;

      // 각 카테고리별로 재료 추가
      for (var categoryEntry in ingredientsByCategory.entries) {
        final category = categoryEntry.key;
        final ingredients = categoryEntry.value;

        for (var ingredientName in ingredients) {
          final key = '$category:$ingredientName';
          
          // 중복 체크
          if (existingIngredients.contains(key)) {
            print('건너뜀 (이미 존재): $category - $ingredientName');
            skippedCount++;
            continue;
          }

          // Firestore에 추가
          await ingredientsCollection.add({
            'name': ingredientName,
            'category': category,
            'createdAt': FieldValue.serverTimestamp(),
          });

          existingIngredients.add(key);
          print('추가됨: $category - $ingredientName');
          addedCount++;
        }
      }

      print('\n=== 추가 완료 ===');
      print('추가된 재료 수: $addedCount');
      print('건너뛴 재료 수: $skippedCount');
      print('총 재료 수: ${addedCount + skippedCount}');
    } catch (e) {
      print('에러 발생: $e');
    }
  }

  // 특정 카테고리만 추가
  Future<void> addIngredientsByCategory(String category) async {
    if (!ingredientsByCategory.containsKey(category)) {
      print('존재하지 않는 카테고리: $category');
      return;
    }

    try {
      final ingredientsCollection = _firestore.collection('ingredients');
      
      // 기존 재료 목록 가져오기 (중복 체크용)
      final existingSnapshot = await ingredientsCollection
          .where('category', isEqualTo: category)
          .get();
      final existingNames = existingSnapshot.docs
          .map((doc) => doc['name'] as String)
          .toSet();

      final ingredients = ingredientsByCategory[category]!;
      int addedCount = 0;
      int skippedCount = 0;

      for (var ingredientName in ingredients) {
        if (existingNames.contains(ingredientName)) {
          print('건너뜀 (이미 존재): $category - $ingredientName');
          skippedCount++;
          continue;
        }

        await ingredientsCollection.add({
          'name': ingredientName,
          'category': category,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('추가됨: $category - $ingredientName');
        addedCount++;
      }

      print('\n=== $category 카테고리 추가 완료 ===');
      print('추가된 재료 수: $addedCount');
      print('건너뛴 재료 수: $skippedCount');
    } catch (e) {
      print('에러 발생: $e');
    }
  }
}

