# 프로젝트 준비 체크리스트

## ✅ 완료된 항목

- [x] 프로젝트 기본 구조 생성
- [x] Firebase 연동 설정
- [x] `firebase_core` 패키지 추가
- [x] `.gitignore` 설정 (`.env`, `firebase_options.dart` 제외)
- [x] README.md 작성 (통합 가이드)
- [x] SETUP_GUIDE.md 작성 (팀원 설정 가이드)
- [x] 프로젝트 구조 및 코딩 가이드 완성

## 📋 팀장이 해야 할 일

### 1. Git 저장소 설정

- [ ] Git 저장소 초기화
  ```bash
  git init
  git add .
  git commit -m "Initial commit: 프로젝트 기본 구조 설정"
  ```

- [ ] GitHub 저장소 생성
  - GitHub.com에서 새 저장소 생성
  - Private 또는 Public 선택

- [ ] GitHub에 연결 및 푸시
  ```bash
  git remote add origin https://github.com/YOUR_USERNAME/flutter_team_project.git
  git branch -M main
  git push -u origin main
  ```

- [ ] 팀원 GitHub 초대
  - Settings → Collaborators → Add people
  - 팀원들의 GitHub 이메일/사용자명 입력
  - "Write" 권한 부여

### 2. Firebase 팀원 초대

- [ ] Firebase Console 접속
  - https://console.firebase.google.com/
  - 프로젝트: `flutterteamproject-ae948`

- [ ] 팀원 초대
  - 프로젝트 설정 → 사용자 및 권한
  - "사용자 추가" 클릭
  - 팀원 Google 계정 이메일 입력
  - 역할: "Editor" 선택

### 3. 본인 설정

- [ ] SHA-1 키 확인 및 등록
  ```bash
  cd android
  .\gradlew signingReport
  ```
  - Firebase Console → 프로젝트 설정 → Android 앱
  - SHA 인증서 지문에 본인 SHA-1 키 등록

- [ ] `.env` 파일 생성 (이미 했다면 체크)
  - `GEMINI_API_KEY=your_api_key_here`

## 👥 팀원들이 해야 할 일

팀원들에게 `SETUP_GUIDE.md` 파일을 공유하세요!

### 팀원 체크리스트:

- [ ] GitHub 초대 수락
- [ ] Firebase 초대 수락
- [ ] 프로젝트 클론
- [ ] `flutter pub get` 실행
- [ ] `.env` 파일 생성 및 API 키 설정
- [ ] `flutterfire configure` 실행
- [ ] SHA-1 키 확인 및 Firebase Console에 등록
- [ ] 개발 시작!

## 🎯 다음 단계

모든 준비가 완료되면:

1. **기능 분담**
   - 각 팀원이 담당할 기능 할당
   - 예: 재료 관리, 레시피, 커뮤니티 등

2. **브랜치 전략**
   - `main`: 메인 브랜치
   - `feature/[기능명]`: 기능 개발 브랜치
   - Pull Request로 코드 리뷰

3. **개발 시작**
   - 각 파일의 주석 가이드 참고
   - README.md의 코딩 규칙 준수

---

**준비 완료! 이제 팀 프로젝트를 시작할 수 있습니다!** 🚀

