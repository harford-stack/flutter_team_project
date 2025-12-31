import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';//미령 추가(닉네임 안나오는 문제)


class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // 미령 추가
  User? _user;
  bool _isLoading = true;
  String? _nickName;//닉네임 추가

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get nickName => _nickName;//getter추가

  AuthProvider() {
    // 인증 상태 리스너 설정
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      _isLoading = false;

      // 사용자 상태 변화시，nickName 끌어옴
      if (user != null) {
        _fetchUserNickName(user.uid);
      } else {
        _nickName = null;  // 로그아웃 시 비움
      }

      notifyListeners();
    });
  }

  // 추가 함수: Firestore에서 닉네임 가져옴
  Future<void> _fetchUserNickName(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        _nickName = doc.data()?['nickname'];//firestore에서는 nickname이라서 먼저 일단 이걸로 고칠게요
        notifyListeners();
      }
    } catch (e) {
      print('사용자 닉네임 가져오기 실패: $e');
    }
  }

  // 구글 로그인
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _authService.signInWithGoogle();

      if (userCredential != null) {
        _user = userCredential.user;
        await _fetchUserNickName(_user!.uid);//로그인 후 닉네임 다져옴
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }


  // 이메일/비밀번호 로그인
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      if (userCredential != null) {
        _user = userCredential.user;
        await _fetchUserNickName(_user!.uid);//로그인 후 닉네임 가져옴
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // 비회원 로그인
  Future<void> signInAnonymously() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signInAnonymously();
      _user = _authService.currentUser;

      if (_user != null) {
        await _fetchUserNickName(_user!.uid);  // 로그인 후 닉네임 가져옴
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // 닉네임 설정
  Future<void> setNickname(String nickname) async {
    await _authService.setNickname(nickname);
    _nickName = nickname;//설정 후 즉시 로컬 캐시 업데이트
    notifyListeners();
  }

  // 닉네임 중복 체크
  Future<bool> checkNicknameExists(String nickname) async {
    return await _authService.checkNicknameExists(nickname);
  }

  // 로그아웃
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _nickName = null;  // nickName를 clear
    notifyListeners();
  }

  // 계정 삭제
  Future<void> deleteAccount() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.deleteAccount();
      _user = null;
      _nickName = null;  // 추가


      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // 닉네임으로 이메일 찾기
  Future<String?> findEmailByNickname(String nickname) async {
    try {
      return await _authService.findEmailByNickname(nickname);
    } catch (e) {
      rethrow;
    }
  }

  // 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // 사용자 프로필 조회
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      return await _authService.getUserProfile();
    } catch (e) {
      rethrow;
    }
  }

  // 사용자 프로필 업데이트
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      await _authService.updateUserProfile(data);

      if (data.containsKey('nickname')) {
        _nickName = data['nickname'];
      }//추가

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // 이메일 변경
  Future<void> updateEmail(String newEmail, String password) async {
    try {
      await _authService.updateEmail(newEmail, password);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // 비밀번호 변경
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      await _authService.updatePassword(currentPassword, newPassword);
    } catch (e) {
      rethrow;
    }
  }

  // 이메일/비밀번호로 회원가입
  Future<bool> signUpWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _authService.signUpWithEmailAndPassword(
        email,
        password,
      );

      if (userCredential != null) {
        _user = userCredential.user;
        await _fetchUserNickName(_user!.uid);//가입 후 닉네임 가져옴
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}

