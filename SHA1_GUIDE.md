# SHA-1 키 확인 및 등록 가이드 (팀원용)

## 🎯 SHA-1 키가 필요한 이유

**SHA-1 키는 Google 로그인(Google Sign-In)을 사용하기 위해 필수입니다!**

Google Sign-In은 보안을 위해 앱의 디지털 서명을 확인합니다:

```
1. 사용자가 "Google로 로그인" 버튼 클릭
   ↓
2. 앱이 Google 서버에 인증 요청
   ↓
3. Google 서버가 확인:
   "이 앱의 SHA-1 키가 Firebase에 등록된 키와 일치하나?"
   ↓
4. 일치하면 ✅ 로그인 성공
   불일치하면 ❌ 로그인 실패
```

**SHA-1 키를 등록하지 않으면:**

- ❌ Google 로그인이 작동하지 않음
- ❌ "이 앱은 Google Sign-In을 사용할 권한이 없습니다" 오류 발생

**SHA-1 키를 등록하면:**

- ✅ Google 로그인 정상 작동
- ✅ Firebase에 등록된 SHA-1 키와 일치하는 앱만 로그인 가능

---

## 🤔 왜 팀원마다 다른 SHA-1 키가 필요한가요?

각 개발자의 컴퓨터마다 **다른 키스토어(keystore) 파일**을 사용하기 때문입니다.

```
팀장의 컴퓨터:
  ~/.android/debug.keystore → SHA-1: AA:BB:CC:DD:EE:FF:...

팀원1의 컴퓨터:
  ~/.android/debug.keystore → SHA-1: 11:22:33:44:55:66:...

팀원2의 컴퓨터:
  ~/.android/debug.keystore → SHA-1: FF:EE:DD:CC:BB:AA:...

팀원3의 컴퓨터:
  ~/.android/debug.keystore → SHA-1: 99:88:77:66:55:44:...
```

**각자의 키스토어 파일이 다르기 때문에** SHA-1 키도 다릅니다!

---

## 📋 SHA-1 키 확인 방법 (Windows)

### 방법 1: gradlew 사용 (권장)

**1단계: Android 폴더로 이동**

```powershell
cd android
```

**2단계: SHA-1 키 확인**

```powershell
.\gradlew signingReport
```

**3단계: 출력에서 SHA-1 찾기**

출력 결과에서 다음 부분을 찾으세요:

```
Variant: debug
Config: debug
Store: C:\Users\...\.android\debug.keystore
Alias: AndroidDebugKey
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

**이 `SHA1:` 뒤의 값이 본인의 SHA-1 키입니다!**

### 방법 2: keytool 사용 (대안)

**1단계: keytool 경로 확인**

```powershell
# Java가 설치되어 있다면
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**2단크: 출력에서 SHA-1 찾기**

출력 결과에서:

```
Certificate fingerprints:
     SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

---

## 📋 SHA-1 키 확인 방법 (Mac/Linux)

### 방법 1: gradlew 사용 (권장)

```bash
cd android
./gradlew signingReport
```

### 방법 2: keytool 사용 (대안)

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

---

## ⚠️ gradlew 명령어가 안 될 때 해결 방법

### 문제 1: "gradlew가 없다" 오류

**해결 방법:**

```powershell
# 프로젝트 루트에서
cd android
# gradlew.bat 파일이 있는지 확인
dir gradlew.bat

# 없다면 Flutter 프로젝트를 다시 생성하거나
# 다른 팀원의 android 폴더를 확인
```

### 문제 2: "권한이 없다" 오류

**해결 방법:**

```powershell
# PowerShell을 관리자 권한으로 실행
# 또는 실행 정책 변경
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 문제 3: "Java가 없다" 오류

**해결 방법:**

1. Android Studio가 설치되어 있다면 Java는 자동으로 포함됨
2. 환경 변수 확인:
   ```powershell
   $env:JAVA_HOME
   ```

### 문제 4: 다른 방법으로 확인하기

**Android Studio에서 확인:**

1. Android Studio 실행
2. 오른쪽 상단의 "Gradle" 탭 클릭
3. `android` → `Tasks` → `android` → `signingReport` 더블클릭
4. 하단의 "Run" 탭에서 SHA-1 키 확인

---

## 🔥 Firebase Console에 등록하기

### 1단계: Firebase Console 접속

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택: `flutterteamproject-ae948`

### 2단계: Android 앱 설정 열기

1. 왼쪽 상단 톱니바퀴 아이콘 클릭
2. "프로젝트 설정" 클릭
3. "내 앱" 섹션에서 **Android 앱** 선택

### 3단계: SHA 인증서 지문 추가

1. "SHA 인증서 지문" 섹션 찾기
2. "지문 추가" 버튼 클릭
3. 본인의 SHA-1 키 입력 (콜론 포함)
   - 예: `AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE`
4. "저장" 클릭

### 4단계: 팀원 모두 등록 확인

**팀원이 4명이면 SHA-1 키도 4개가 등록되어야 합니다!**

```
Firebase Console → Android 앱 → SHA 인증서 지문:
  ✅ AA:BB:CC:DD:... (팀장)
  ✅ 11:22:33:44:... (팀원1)
  ✅ FF:EE:DD:CC:... (팀원2)
  ✅ 99:88:77:66:... (팀원3)
```

---

## ✅ 체크리스트

각 팀원이 확인해야 할 사항:

- [ ] 본인의 SHA-1 키 확인 완료
- [ ] Firebase Console에 본인의 SHA-1 키 등록 완료
- [ ] Google 로그인 테스트 성공
- [ ] 팀원 모두의 SHA-1 키가 Firebase Console에 등록되어 있는지 확인

---

## ❓ 자주 묻는 질문

### Q: 예전에 백업해둔 SHA-1 키(또는 키스토어)를 사용해도 되나요?

**A: 네, 사용할 수 있습니다! 하지만 확인이 필요합니다.**

#### 경우 1: 키스토어 파일을 백업한 경우 ✅

**백업한 키스토어 파일을 사용하면:**

- ✅ 같은 SHA-1 키 사용 가능
- ✅ 예전 프로젝트와 동일한 키 사용
- ✅ Firebase Console에 등록만 하면 됨

**사용 방법:**

```powershell
# 백업한 키스토어 파일을 ~/.android/debug.keystore 위치에 복사
# 또는 프로젝트의 android/app/ 폴더에 복사 후 설정
```

**주의사항:**

- 키스토어 파일을 잃어버리면 복구 불가능하므로 안전하게 보관
- 다른 사람과 공유하지 않기

#### 경우 2: SHA-1 키만 백업한 경우 ⚠️

**SHA-1 키만 백업했다면:**

- ❌ 키스토어 파일이 없으면 사용 불가
- ✅ 키스토어 파일이 있다면 같은 SHA-1 키가 나옴

**확인 방법:**

```powershell
# 현재 키스토어에서 SHA-1 키 확인
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# 백업한 SHA-1 키와 비교
```

#### 경우 3: 새로운 키스토어를 사용하는 경우

**새로운 키스토어를 사용하면:**

- 새로운 SHA-1 키가 생성됨
- 백업한 SHA-1 키와 다를 수 있음
- Firebase Console에 새로운 SHA-1 키 등록 필요

**결론:**

- ✅ 백업한 키스토어 파일이 있다면 사용 가능
- ✅ 같은 SHA-1 키를 사용하고 싶다면 백업한 키스토어 파일 사용
- ✅ 새로운 키를 사용해도 문제없음 (Firebase Console에 등록만 하면 됨)

### Q: 팀원이 4명이면 SHA-1 키도 4개인가요?

**A: 네, 맞습니다!**

각 개발자의 컴퓨터마다 다른 키스토어를 사용하므로:

- 팀원 4명 = SHA-1 키 4개
- Firebase Console에 **모두 등록**해야 합니다

### Q: 다른 팀원의 SHA-1 키를 사용할 수 있나요?

**A: 불가능합니다!**

각자의 키스토어 파일이 다르기 때문에 다른 사람의 SHA-1 키를 사용할 수 없습니다.

### Q: gradlew 명령어가 안 되면 어떻게 하나요?

**A: Android Studio에서 확인하세요!**

1. Android Studio 실행
2. Gradle 탭 → `android` → `Tasks` → `android` → `signingReport` 실행
3. Run 탭에서 SHA-1 키 확인

### Q: SHA-1 키를 등록하지 않으면 어떻게 되나요?

**A: Google 로그인이 작동하지 않습니다!**

- ❌ "이 앱은 Google Sign-In을 사용할 권한이 없습니다" 오류 발생
- ❌ 로그인 버튼을 눌러도 실패

---

## 🆘 문제 해결

### 문제: gradlew 명령어 실행이 안 됨

**해결 방법들:**

1. **Android Studio에서 확인**

   - 가장 쉬운 방법
   - Gradle 탭에서 signingReport 실행

2. **keytool 직접 사용**

   ```powershell
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```

3. **다른 팀원에게 도움 요청**
   - 이미 등록한 팀원이 방법을 알려줄 수 있음

---

**각 팀원은 반드시 본인의 SHA-1 키를 Firebase Console에 등록해야 Google 로그인이 작동합니다!** 🔐
