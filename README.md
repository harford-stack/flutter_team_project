# 🍳 ShakeCook

> **"흔들어서 만드는 AI 레시피 추천 앱"**

재료를 선택하고 폰을 흔들면 AI가 맞춤형 레시피를 추천해주는 Flutter 기반 모바일 앱입니다.  
냉장고 재료를 관리하고, 커뮤니티에서 레시피를 공유하며, AI의 도움으로 새로운 요리를 만들어보세요.

![Flutter](https://img.shields.io/badge/Flutter-3.10.3-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![Google Gemini](https://img.shields.io/badge/Google_Gemini-4285F4?logo=google&logoColor=white)

<img src="README_IMG/image_readme.JPG">

---

## 💡 프로젝트 소개

**ShakeCook**은 사용자가 보유한 재료를 기반으로 AI가 맞춤형 레시피를 추천해주는 모바일 앱입니다.

### 핵심 컨셉

- **AI 기반 레시피 추천**: Google Gemini API를 활용한 지능형 레시피 생성
- **흔들기 제스처**: 폰을 흔들어 재미있게 레시피 생성하기
- **재료 관리**: 냉장고 재료를 이미지 인식 또는 직접 선택으로 관리
- **커뮤니티**: 레시피와 요리 경험을 공유하는 소셜 플랫폼

---

## 📆 개발 기간

25.12.22 ~ 26.01.08

---

## 😃 팀원 구성

| 팀원 | git |
|------|----------|
| 김지훈(팀장) | https://github.com/harford-stack |
| 박충현 | https://github.com/3y5adf |
| 이미령 | https://github.com/li33893 |
| 최현지 | https://github.com/chchjjj |

---

## 🎯 주요 기능

### 🤖 AI 레시피 추천(최현지)

- **Google Gemini AI 연동**: 선택한 재료로 맞춤 레시피 3개 생성
- **흔들기 제스처**: 폰을 흔들어 레시피 생성 (진행률 표시)
- **재료 기반 추천**: 보유 재료만으로 가능한 레시피 제안
- **키워드/테마 추가**: 재료 키워드, 원하는 컨셉의 테마 선택
- **레시피 상세 정보**: 재료 목록, 조리 과정, 저장 기능

### 🥬 재료 관리(박충현)

- **내 냉장고**: 보유한 재료를 관리
- **이미지 인식**: 사진 촬영으로 재료 자동 인식
- **직접 선택**: 재료 목록에서 직접 선택하여 추가
- **재료 추가/삭제**: SpeedDial을 활용한 직관적인 재료 관리
- **재료 아이콘**: 각 재료별 맞춤 아이콘 표시

### 👥 사용자 인증(김지훈)

- **이메일/비밀번호 로그인**: 기본 인증 시스템
- **구글 로그인**: 소셜 로그인 지원
- **회원가입**: 닉네임, 이메일, 비밀번호로 가입
- **프로필 관리**: 닉네임 수정
- **비밀번호 재설정**: 이메일 기반 비밀번호 찾기

### 💬 커뮤니티(이미령)

- **게시글 작성**: 레시피와 요리 경험 공유
- **이미지 업로드**: Firebase Storage를 활용한 이미지 저장
- **댓글/대댓글**: 게시글에 댓글 작성 및 답글 기능
- **북마크**: 관심 있는 게시글 저장
- **카테고리 필터**: 자유게시판, 문의사항 등 카테고리별 필터링
- **검색 기능**: 제목 및 내용 검색
- **정렬 기능**: 최신순/인기순 정렬

### 🔔 알림 시스템(이미령)

- **알림 목록**: 북마크, 댓글 등 다양한 알림
- **실시간 업데이트**: 새로운 알림 즉시 확인

---

## 📄발표 자료
- [발표 자료 PDF](https://drive.google.com/file/d/1hAftl4qNVxNpMnI7Bf-AxmqCZkTGx99Y/view?usp=sharing)

---

## 🎞시연 영상
- [시연 영상 - 레시피](https://drive.google.com/file/d/1TPqrsv1HfOuypzmF15YKfcdcK_kkpxq0/view?usp=sharing)
- [시연 영상 - 사용자 인증](https://drive.google.com/file/d/1dn4GZvbSlUclIDuYLoQFCsw9QQXmMJoF/view?usp=sharing)
- [시연 영상 - 재료 관리](https://drive.google.com/file/d/1tJtbaObTNpCF5yX9e-aY7ZuXjlsFt6qT/view?usp=sharing)
- [시연 영상 - 커뮤니티&알림 시스템](https://drive.google.com/file/d/1FtAhvKH7XS97wUC3J0onWJ-WjTDgdQ7q/view?usp=sharing)

---

## 🛠 사용 기술

### Frontend

| 기술명                                                                                                                  | 설명                                          |
| ----------------------------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| ![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)                                    | Flutter 3.10.3 - 크로스 플랫폼 모바일 앱 개발 |

### Backend & Services

| 기술명                                                                                                  | 설명                                  |
| ------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| ![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)                 | Firebase - 백엔드 서비스              |
| ![Firebase Auth](https://img.shields.io/badge/Firebase_Auth-FFCA28?logo=firebase&logoColor=black)       | Firebase Authentication - 사용자 인증 |
| ![Cloud Firestore](https://img.shields.io/badge/Cloud_Firestore-FFCA28?logo=firebase&logoColor=black)   | Cloud Firestore - NoSQL 데이터베이스  |
| ![Firebase Storage](https://img.shields.io/badge/Firebase_Storage-FFCA28?logo=firebase&logoColor=black) | Firebase Storage - 이미지 저장        |
| ![Google Gemini](https://img.shields.io/badge/Google_Gemini-4285F4?logo=google&logoColor=white)         | Google Gemini AI - 레시피 생성 AI     |

### 주요 패키지

| 패키지명               | 용도                  |
| ---------------------- | --------------------- |
| `image_picker`         | 이미지 선택 및 촬영   |
| `google_sign_in`       | 구글 로그인           |
| `google_generative_ai` | Google Gemini AI 연동 |
| `carousel_slider`      | 이미지 슬라이더       |
| `flutter_speed_dial`   | SpeedDial 메뉴        |
| `shake`                | 흔들기 제스처 감지    |
| `percent_indicator`    | 진행률 표시           |
| `tutorial_coach_mark`  | 튜토리얼 가이드       |
| `shared_preferences`   | 로컬 데이터 저장      |

---

<details>
   <summary><strong>📁 프로젝트 구조</strong></summary>
   
   ```
   lib/
   ├── auth/                    # 인증 관련
   │   ├── auth_provider.dart   # 인증 상태 관리
   │   ├── auth_service.dart    # 인증 서비스
   │   ├── login_screen.dart    # 로그인 화면
   │   ├── signup_screen.dart   # 회원가입 화면
   │   ├── home_screen.dart     # 홈 화면
   │   └── ...
   │
   ├── ingredients/             # 재료 관리
   │   ├── user_refrigerator.dart      # 내 냉장고 화면
   │   ├── select_screen.dart          # 재료 선택 화면
   │   ├── image_confirm.dart          # 이미지 인식 확인
   │   ├── user_ingredient_add.dart    # 재료 추가
   │   ├── user_ingredient_remove.dart # 재료 삭제
   │   └── ...
   │
   ├── recipes/                 # 레시피 관련
   │   ├── recipe_ai_service.dart      # AI 레시피 생성 서비스
   │   ├── recipe_service.dart         # 레시피 서비스
   │   ├── recipeDetail_screen.dart    # 레시피 상세 화면
   │   ├── recipesList_screen.dart     # 레시피 목록 화면
   │   ├── shaking_widget.dart         # 흔들기 위젯
   │   └── ...
   │
   ├── community/               # 커뮤니티
   │   ├── screens/            # 커뮤니티 화면들
   │   │   ├── community_list_screen.dart    # 게시글 목록
   │   │   ├── community_detail_screen.dart  # 게시글 상세
   │   │   ├── post_editor_screen.dart       # 게시글 작성/수정
   │   │   └── ...
   │   ├── models/             # 데이터 모델
   │   │   ├── post_model.dart
   │   │   └── comment_model.dart
   │   ├── services/           # 서비스
   │   │   ├── post_service.dart
   │   │   ├── comment_service.dart
   │   │   └── bookmark_service.dart
   │   └── widgets/            # 커뮤니티 위젯들
   │
   ├── common/                 # 공통 사용 파일
   │   ├── app_colors.dart     # 색상 상수
   │   ├── custom_appbar.dart  # 커스텀 앱바
   │   ├── custom_footer.dart  # 커스텀 푸터
   │   ├── custom_drawer.dart  # 커스텀 드로어
   │   └── ...
   │
   ├── providers/              # 상태 관리
   │   └── temp_ingre_provider.dart  # 임시 재료 저장
   │
   ├── notifications/          # 알림
   │   ├── notification_screen.dart
   │   └── notification_service.dart
   │
   └── main.dart              # 앱 시작점
   ```

</details>


---

<details>
   <summary><strong>🚀 시작하기</strong></summary>

   ### 필수 요구사항

- Flutter SDK (3.10.3 이상)
- Dart SDK
- Android Studio / VS Code
- Firebase 프로젝트
- Google Gemini API 키

### 설치 및 실행

```bash
# 저장소 클론
git clone [저장소 URL]
cd flutter_team_project

# 패키지 설치
flutter pub get

# .env 파일 생성 (프로젝트 루트에)
# GEMINI_API_KEY=your_gemini_api_key_here

# Firebase 설정
# flutterfire configure --project=flutterteamproject-ae948

# 앱 실행
flutter run
```

### 환경 변수 설정

프로젝트 루트에 `.env` 파일을 생성하고 다음 내용을 추가하세요:

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

⚠️ **주의**: `.env` 파일은 Git에 커밋되지 않습니다. 각자 본인의 API 키를 발급받아 사용하세요.

### Firebase 설정

1. **Firebase 프로젝트 생성**

   - Firebase Console에서 새 프로젝트 생성
   - Android/iOS 앱 등록

2. **Firebase CLI 설정**

   ```bash
   flutterfire configure --project=flutterteamproject-ae948
   ```

3. **SHA-1 키 등록** (구글 로그인용)

   - 각 팀원마다 SHA-1 키가 다릅니다
   - 각자 본인의 SHA-1 키를 Firebase Console에 등록해야 합니다
   - 자세한 방법은 `SETUP_GUIDE.md` 참고

4. **Firestore 규칙 설정**

   - Firebase Console → Firestore Database → Rules
   - 적절한 보안 규칙 설정

5. **Storage 규칙 설정**
   - Firebase Console → Storage → Rules
   - 이미지 업로드 권한 설정
   
</details>



---

<details>
   <summary><strong>📄 주요 기능 상세</strong></summary>
   
   ### AI 레시피 추천 플로우

   1. **재료 선택**
   
      - 이미지 촬영/선택으로 재료 인식
      - 또는 재료 목록에서 직접 선택
   
   2. **레시피 생성**
   
      - "쉐킷하시겠어요?" 팝업
      - "지금 쉐-킷!" 버튼 클릭
      - 폰을 흔들어 진행률 100% 달성
      - AI가 레시피 3개 생성
   
   3. **레시피 확인**
      - 생성된 레시피 목록 확인
      - 레시피 상세 정보 확인
      - 내 레시피에 저장
   
   ### 재료 관리 플로우
   
   1. **재료 추가**
   
      - SpeedDial 메뉴에서 "재료 추가하기" 선택
      - 카테고리별 재료 선택
      - 또는 이미지로 재료 인식
   
   2. **재료 삭제**
   
      - SpeedDial 메뉴에서 "재료 삭제하기" 선택
      - 삭제할 재료 선택
   
   3. **재료 확인**
      - 내 냉장고 화면에서 카테고리별 재료 확인
      - 재료 아이콘과 이름으로 표시
   
   ### 커뮤니티 플로우
   
   1. **게시글 작성**
   
      - 커뮤니티 화면에서 "+" 버튼 클릭
      - 제목, 내용, 이미지, 카테고리 입력
      - 게시글 업로드
   
   2. **게시글 조회**
   
      - 게시글 목록에서 카테고리 필터링
      - 검색으로 원하는 게시글 찾기
      - 최신순/인기순 정렬
   
   3. **댓글 및 북마크**
      - 게시글 상세에서 댓글 작성
      - 대댓글 작성 가능
      - 북마크로 관심 게시글 저장
</details>




---

## 💡 배운 점

- **Flutter 상태 관리**: Provider 패턴을 통한 효율적인 상태 관리
- **Firebase 통합**: Firestore, Storage, Auth의 통합 활용
- **AI API 연동**: Google Gemini API를 활용한 레시피 생성
- **제스처 인식**: 흔들기 제스처를 활용한 인터랙티브 UX
- **이미지 처리**: 이미지 선택, 업로드, 표시의 전체 플로우

---
