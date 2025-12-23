# 냉장고를 부탁해 - 프로젝트 가이드

## 📋 목차
1. [프로젝트 개요](#프로젝트-개요)
2. [프로젝트 구조](#프로젝트-구조)
3. [파일별 작성 규칙](#파일별-작성-규칙)
4. [위젯 작성 위치 가이드](#위젯-작성-위치-가이드)
5. [시작하기](#시작하기)

---

## 프로젝트 개요

**냉장고를 부탁해**는 냉장고 속 식재료를 창의적으로 활용하고, 요리 과정을 게임처럼 즐기며, 음식물 쓰레기를 줄이는 데 기여하는 플러터 앱입니다.

### 주요 기능
- 📸 **사진 인식**: AI로 냉장고/재료 사진에서 자동 인식
- ✍️ **수동 입력**: 텍스트로 직접 재료 추가
- 📅 **유통기한 관리**: 재료별 유통기한 기록 및 알림
- 🎲 **흔들기 레시피**: 핸드폰 흔들기로 랜덤 레시피 추천
- 🤖 **AI 레시피 생성**: 보유 재료 기반 레시피 생성
- 👥 **커뮤니티**: 레시피 공유 및 소통

---

## 프로젝트 구조 (실습용 라이트 버전)

### 📁 추천 폴더 구조 (2주 실습용, 최대한 단순하게)

```
lib/
├── main.dart            # 앱 시작점
├── screens/             # 모든 화면(페이지) 모음
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── ingredient_add_screen.dart
│   ├── ingredient_select_screen.dart
│   ├── recipe_shake_screen.dart
│   ├── recipe_result_screen.dart
│   ├── community_list_screen.dart
│   ├── community_detail_screen.dart
│   ├── community_create_screen.dart
│   ├── bookmark_list_screen.dart
│   └── profile_screen.dart
│
├── widgets/             # 재사용 위젯
│   ├── loading_widget.dart
│   ├── error_widget.dart
│   ├── empty_state_widget.dart
│   ├── ingredient_camera_widget.dart
│   ├── ingredient_manual_input_widget.dart
│   └── google_sign_in_button.dart
│
├── models/              # 데이터 모델
│   ├── ingredient.dart
│   ├── recipe.dart
│   ├── community_post.dart
│   └── user_model.dart
│
├── services/            # 비즈니스 로직
│   ├── ai_service.dart
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── sensor_service.dart
│
└── core/                # (선택) 공통 유틸, 테마, 상수
    ├── app_theme.dart
    ├── app_constants.dart
    └── utils.dart
```

> **실제 저장소에는 `features/`, `core/*/`, `widgets/common/` 같은 좀 더 깊은 구조가 미리 만들어져 있습니다.**  
> 이번 **2주 실습**에서는 위에 나온 **라이트 구조만 신경 쓰고**, 나머지 폴더는 *참고용/확장용*으로만 봐도 됩니다.

### 📂 각 폴더 역할 (라이트 버전 기준)

| 폴더 | 역할 | 예시 |
|-----|------|------|
| `screens/` | 화면(페이지) 파일 | `home_screen.dart`, `login_screen.dart` |
| `widgets/` | 재사용 가능한 위젯 | `loading_widget.dart`, `ingredient_camera_widget.dart` |
| `models/` | 데이터 구조 정의 | `ingredient.dart`, `recipe.dart` |
| `services/` | 비즈니스 로직 | `auth_service.dart`, `firestore_service.dart` |
| `core/` | (선택) 상수/테마/유틸 | `app_theme.dart`, `app_constants.dart`, `utils.dart` |

---

## 파일별 작성 규칙

### ⚠️ 중요: 각 파일은 명확한 역할이 있습니다!

### 1. 화면 파일 (`screens/`)

**위치**: `screens/[화면명]_screen.dart`

**작성 내용**:
- ✅ UI 레이아웃과 화면 구성
- ✅ 다른 위젯들을 조합하여 화면 구성
- ✅ 일회용 위젯 (같은 파일 안에 private 클래스로)

**작성하지 않을 것**:
- ❌ 비즈니스 로직 → `services/`에 작성
- ❌ 재사용 가능한 위젯 → `widgets/`에 작성
- ❌ 데이터 모델 정의 → `models/`에 작성

**예시**:
```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _HomeBannerWidget(), // 일회용 위젯
          IngredientCardWidget(), // 재사용 위젯
        ],
      ),
    );
  }
}

// 일회용 위젯 (이 화면에서만 사용)
class _HomeBannerWidget extends StatelessWidget {
  // 홈 화면 전용 UI
}
```

---

### 2. 위젯 파일 (`widgets/`)

**위치**: 
- `widgets/` - 재사용 가능한 위젯은 전부 여기 한 곳에 둡니다.

**작성 내용**:
- ✅ 여러 화면에서 재사용 가능한 UI 컴포넌트
- ✅ 공통으로 사용하는 버튼, 카드, 리스트 아이템 등

**작성하지 않을 것**:
- ❌ Scaffold 사용 (화면이 아니므로)
- ❌ 비즈니스 로직 (services/에 작성)

---

### 3. 모델 파일 (`models/`)

**위치**: `models/[모델명].dart`

**작성 내용**:
- ✅ 데이터 구조 정의 (필드)
- ✅ toMap(), fromMap() 메서드 (Firestore 변환)
- ✅ copyWith() 메서드 (선택)

**작성하지 않을 것**:
- ❌ UI 코드
- ❌ 비즈니스 로직

---

### 4. 서비스 파일 (`services/`)

**위치**: `services/[서비스명]_service.dart`

**작성 내용**:
- ✅ 비즈니스 로직
- ✅ 외부 API 호출
- ✅ 데이터베이스 연동
- ✅ 데이터 처리 로직

**작성하지 않을 것**:
- ❌ UI 코드
- ❌ Widget 클래스

---

## 위젯 작성 위치 가이드 (라이트 버전)

이번 실습에서는 **위치 고민을 최소화**하기 위해 규칙을 아주 단순하게 가져갑니다.

### 🤔 어디에 만들면 되나요?

- **이 화면에서만 쓰는 위젯**  
  → 해당 `screen` 파일 안에 **private 클래스**로 작성  
  → 예: `_HomeBannerWidget`

- **여러 화면에서 재사용하는 위젯**  
  → `widgets/` 폴더에 **새 파일**로 작성  
  → 예: `loading_widget.dart`, `ingredient_camera_widget.dart`

이 정도만 지켜도 충분합니다.  
`features/`, `widgets/common/` 같은 더 복잡한 구조는 **신경 쓰지 않아도 됩니다.**

---

## 시작하기

### 1. 프로젝트 클론 후 설정

```bash
# 저장소 클론
git clone [저장소 URL]
cd flutter_team_project

# 패키지 설치
flutter pub get

# .env 파일 생성 (프로젝트 루트에)
# .env.example 파일을 참고하여 .env 파일을 생성하세요
# GEMINI_API_KEY=your_api_key_here

# Firebase 설정 (처음 한 번만)
flutterfire configure --project=flutterteamproject-ae948
```

### 2. .env 파일 설정

프로젝트 루트에 `.env` 파일을 생성하고 다음 내용을 추가하세요:

```
GEMINI_API_KEY=your_gemini_api_key_here
```

⚠️ **주의**: `.env` 파일은 Git에 커밋되지 않습니다. 각자 본인의 API 키를 발급받아 사용하세요.

### 2. Firebase 설정

- Firebase 프로젝트 생성
- `flutterfire configure` 실행
- **SHA-1 키 등록** (구글 로그인용)
  - ⚠️ **각 팀원마다 SHA-1 키가 다릅니다!**
  - 각자 본인의 SHA-1 키를 Firebase Console에 등록해야 합니다
  - 자세한 방법은 `SETUP_GUIDE.md` 참고

### 3. 작업 시작

각 파일에 주석으로 가이드가 작성되어 있습니다. 파일을 열면 작성 방법을 확인할 수 있습니다.

---

## ✅ 체크리스트

코드를 작성할 때:

- [ ] 화면 파일(`screens/`)에 비즈니스 로직이 없나요?
- [ ] 재사용 가능한 위젯은 `widgets/` 폴더에 분리했나요?
- [ ] 일회용 위젯은 해당 화면 파일 안에 private 클래스로 작성했나요?
- [ ] 데이터 모델은 `models/` 폴더에 있나요?
- [ ] 서비스 로직은 `services/` 폴더에 있나요?

---

## 📝 예시: 재료 등록 화면 구현

### 올바른 구조:

```
ingredient_add_screen.dart (화면)
  ├─ _IngredientFormWidget (일회용 위젯 - 같은 파일 안)
  ├─ IngredientCameraWidget (재사용 위젯 - widgets/ 폴더)
  ├─ Ingredient 모델 사용 (models/ 폴더)
  └─ FirestoreService 사용 (services/ 폴더)
```

### 잘못된 구조:

```
ingredient_add_screen.dart
  ├─ 모든 UI 코드
  ├─ 모든 로직
  ├─ 모델 정의
  └─ 서비스 로직
  (모든 것이 한 파일에) ❌
```

---

## ❓ 자주 묻는 질문

**Q: 새로운 화면을 만들려면?**  
A: `features/[기능명]/screens/` 폴더에 새 파일 생성

**Q: 공통으로 사용하는 함수는 어디에?**  
A: `core/utils/` 폴더에 추가

**Q: 데이터베이스 연동은 어디에?**  
A: `services/firestore_service.dart`에 메서드 추가

**Q: 색상이나 스타일 변경은?**  
A: `core/theme/app_theme.dart` 수정

**Q: 위젯을 어디에 작성해야 할지 모르겠어요**  
A: 일회용으로 시작하고, 필요할 때 리팩토링하세요!

---

이 가이드를 따라주시면 깔끔하고 유지보수하기 쉬운 코드를 작성할 수 있습니다! 🚀
