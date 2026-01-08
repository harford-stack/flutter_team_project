# 프로젝트 설정 가이드

## 🚀 Git 저장소 설정 (팀장)

### 1단계: Git 저장소 초기화

```bash
# Git 저장소 초기화
git init

# .gitignore 확인 (이미 설정되어 있음)
# .env, firebase_options.dart 등은 자동으로 제외됨
```

### 2단계: 첫 커밋

```bash
# 모든 파일 추가
git add .

# 첫 커밋
git commit -m "Initial commit: 프로젝트 기본 구조 설정"
```

### 3단계: GitHub 저장소 생성 및 연결

1. **GitHub에서 새 저장소 생성**
   - GitHub.com 접속
   - "New repository" 클릭
   - 저장소 이름: `flutter_team_project` (또는 원하는 이름)
   - Private 또는 Public 선택
   - "Create repository" 클릭

2. **로컬 저장소와 연결**

```bash
# 원격 저장소 추가 (YOUR_USERNAME을 본인 GitHub 사용자명으로 변경)
git remote add origin https://github.com/YOUR_USERNAME/flutter_team_project.git

# 메인 브랜치 이름 설정
git branch -M main

# 원격 저장소에 푸시
git push -u origin main
```

### 4단계: 팀원 초대

1. **GitHub 저장소 설정**
   - 저장소 페이지에서 "Settings" 클릭
   - 왼쪽 메뉴에서 "Collaborators" 클릭
   - "Add people" 버튼 클릭
   - 팀원들의 GitHub 이메일 또는 사용자명 입력
   - 권한 선택 (보통 "Write" 권한)
   - 초대 전송

2. **팀원들이 받을 초대**
   - 팀원들은 GitHub 이메일로 초대장을 받음
   - 초대장의 링크를 클릭하여 수락

---

## 🔥 Firebase 프로젝트 초대 (팀장)

### 1단계: Firebase Console 접속

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택: `flutterteamproject-ae948`

### 2단계: 팀원 초대

1. **프로젝트 설정 열기**
   - 왼쪽 상단 톱니바퀴 아이콘 클릭
   - "프로젝트 설정" 클릭

2. **사용자 및 권한 탭**
   - "사용자 및 권한" 탭 클릭
   - "사용자 추가" 버튼 클릭

3. **팀원 이메일 추가**
   - 팀원의 Google 계정 이메일 입력
   - 역할 선택:
     - **Editor**: 개발 권한 (권장)
     - **Viewer**: 읽기 전용
   - "추가" 클릭

4. **팀원 확인**
   - 팀원들은 이메일로 초대장을 받음
   - 초대장의 링크를 클릭하여 수락

---

## 👥 팀원 설정 가이드

### 1단계: 프로젝트 클론

```bash
# 저장소 클론
git clone https://github.com/YOUR_USERNAME/flutter_team_project.git
cd flutter_team_project
```

### 2단계: 패키지 설치

```bash
# 패키지 설치
flutter pub get
```

### 3단계: .env 파일 생성

프로젝트 루트에 `.env` 파일을 생성하세요:

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

**API 키 발급 방법:**
1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 선택: `FlutterTeamProject`
3. "API 및 서비스" > "사용자 인증 정보"
4. "사용자 인증 정보 만들기" > "API 키"
5. 생성된 API 키를 `.env` 파일에 입력

### 4단계: Firebase 설정

```bash
# Firebase CLI 설치 (처음 한 번만)
npm install -g firebase-tools

# Firebase 로그인
firebase login

# FlutterFire CLI 설치
flutter pub global activate flutterfire_cli

# Firebase 프로젝트 연결
flutterfire configure --project=flutterteamproject-ae948
```

### 5단계: SHA-1 키 등록 (Google Sign-In용)

**⚠️ 중요: 각 팀원마다 SHA-1 키가 다릅니다!**

각 팀원은 본인의 SHA-1 키를 Firebase Console에 등록해야 합니다.

#### SHA-1 키 확인 방법

```bash
# Android 폴더로 이동
cd android

# SHA-1 키 확인 (Windows)
.\gradlew signingReport

# SHA-1 키 확인 (Mac/Linux)
./gradlew signingReport
```

출력에서 다음을 찾으세요:
```
Variant: debug
Config: debug
Store: C:\Users\...\.android\debug.keystore
Alias: AndroidDebugKey
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

#### Firebase Console에 등록

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 `flutterteamproject-ae948` 선택
3. 왼쪽 상단 톱니바퀴 → "프로젝트 설정"
4. "내 앱" 섹션에서 Android 앱 선택
5. "SHA 인증서 지문" 섹션에서 "지문 추가" 클릭
6. 본인의 SHA-1 키 입력 (콜론 포함)
7. "저장" 클릭

**각 팀원이 본인의 SHA-1 키를 등록해야 Google Sign-In이 작동합니다!**

### 5단계: 개발 시작

이제 개발을 시작할 수 있습니다! 각 파일의 주석을 참고하여 작업하세요.

---

## ⚠️ 주의사항

### 절대 Git에 커밋하면 안 되는 파일

- `.env` - API 키가 포함되어 있음
- `firebase_options.dart` - 이미 `.gitignore`에 포함됨
- `google-services.json` - Android Firebase 설정
- `GoogleService-Info.plist` - iOS Firebase 설정

### 커밋 전 확인사항

```bash
# 커밋 전 상태 확인
git status

# .env 파일이 보이면 안 됨!
# firebase_options.dart가 보이면 안 됨!
```

### 브랜치 전략 (권장)

```bash
# 기능별 브랜치 생성
git checkout -b feature/ingredient-add

# 작업 후 커밋
git add .
git commit -m "feat: 재료 추가 기능 구현"

# 원격 저장소에 푸시
git push origin feature/ingredient-add

# GitHub에서 Pull Request 생성
```

---

## 📝 체크리스트

### 팀장

- [ ] Git 저장소 생성 및 초기 커밋
- [ ] GitHub 저장소 생성 및 연결
- [ ] 팀원들 GitHub 초대
- [ ] Firebase 프로젝트에 팀원 초대
- [ ] README.md 확인

### 팀원

- [ ] GitHub 초대 수락
- [ ] Firebase 초대 수락
- [ ] 프로젝트 클론
- [ ] `flutter pub get` 실행
- [ ] `.env` 파일 생성 및 API 키 설정
- [ ] `flutterfire configure` 실행
- [ ] 개발 시작!

---

이제 팀 프로젝트를 시작할 준비가 되었습니다! 🚀

