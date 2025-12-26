import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // 인증 상태 리스너 설정
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  // 구글 로그인
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential != null) {
        _user = userCredential.user;
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

  // 네이버 로그인
  // 네이버 SDK로 로그인 후 받은 사용자 정보를 전달
  Future<bool> signInWithNaver({
    required String email,
    required String name,
    String? photoUrl,
    String? naverId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _authService.signInWithNaver(
        email: email,
        name: name,
        photoUrl: photoUrl,
        naverId: naverId,
      );
      
      if (userCredential != null) {
        _user = userCredential.user;
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

  // 카카오 로그인
  // 카카오 SDK로 로그인 후 받은 사용자 정보를 전달
  Future<bool> signInWithKakao({
    required String email,
    required String name,
    String? photoUrl,
    String? kakaoId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _authService.signInWithKakao(
        email: email,
        name: name,
        photoUrl: photoUrl,
        kakaoId: kakaoId,
      );
      
      if (userCredential != null) {
        _user = userCredential.user;
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
    notifyListeners();
  }
}

