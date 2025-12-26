import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 현재 사용자 가져오기
  User? get currentUser => _auth.currentUser;

  // 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 구글 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Google Sign-In 플로우 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // 사용자가 로그인 취소
        return null;
      }

      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase 인증 정보 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase에 로그인
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // 첫 로그인인지 확인
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser && userCredential.user != null) {
        // 새 사용자일 경우 Firestore에 사용자 정보 저장
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'displayName': userCredential.user!.displayName,
          'photoURL': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      print('구글 로그인 오류: $e');
      rethrow;
    }
  }

  // 네이버 로그인 (백엔드 없이 구현)
  // 네이버 SDK로 로그인 후 받은 사용자 정보로 Firebase 사용자 생성
  Future<UserCredential?> signInWithNaver({
    required String email,
    required String name,
    String? photoUrl,
    String? naverId,
  }) async {
    try {
      // 이메일이 없으면 에러
      if (email.isEmpty) {
        throw Exception('네이버 로그인: 이메일 정보가 없습니다');
      }

      UserCredential? userCredential;

      try {
        // 먼저 이메일로 로그인 시도 (이미 가입된 사용자)
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: _generateTemporaryPassword(email), // 임시 비밀번호
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          // 사용자가 없거나 비밀번호가 틀린 경우, 또는 다른 provider로 이미 가입된 경우 새로 생성
          // invalid-credential은 이미 다른 provider(구글 등)로 같은 이메일로 가입된 경우 발생할 수 있음
          // 임시 비밀번호 생성 (이메일 기반으로 일관성 유지)
          final tempPassword = _generateTemporaryPassword(email);
          
          try {
            userCredential = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: tempPassword,
            );
          } on FirebaseAuthException catch (createError) {
            // 이미 같은 이메일로 가입된 경우 (다른 provider로)
            if (createError.code == 'email-already-in-use') {
              // Anonymous Authentication 사용
              print('이미 다른 방식으로 가입된 이메일입니다. Anonymous Authentication을 사용합니다.');
              userCredential = await _auth.signInAnonymously();
              
              // Firestore에 이메일 정보 저장 (이메일은 검증되지 않음)
            } else {
              rethrow;
            }
          }
        } else if (e.code == 'operation-not-allowed') {
          // 이메일/비밀번호 방식이 비활성화된 경우 Anonymous Authentication 사용
          print('이메일/비밀번호 방식이 비활성화되어 있습니다. Anonymous Authentication을 사용합니다.');
          userCredential = await _auth.signInAnonymously();
          
          // Anonymous 사용자에 이메일 연결 시도 (실패해도 계속 진행)
          if (userCredential.user != null) {
            try {
              await userCredential.user!.updateEmail(email);
            } catch (updateError) {
              print('이메일 업데이트 실패 (무시): $updateError');
            }
          }
        } else {
          rethrow;
        }
      }

      if (userCredential.user != null) {
        // Firestore에 사용자 정보 저장
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? true;
        
        if (isNewUser) {
          // 새 사용자일 경우 Firestore에 저장
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'email': email,
            'displayName': name,
            'photoURL': photoUrl,
            'provider': 'naver',
            'naverId': naverId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // 기존 사용자 정보 업데이트
          await _firestore.collection('users').doc(userCredential.user!.uid).update({
            'displayName': name,
            'photoURL': photoUrl,
            'provider': 'naver',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;
    } catch (e) {
      print('네이버 로그인 오류: $e');
      rethrow;
    }
  }

  // 카카오 로그인 (백엔드 없이 구현)
  // 카카오 SDK로 로그인 후 받은 사용자 정보로 Firebase 사용자 생성
  Future<UserCredential?> signInWithKakao({
    required String email,
    required String name,
    String? photoUrl,
    String? kakaoId,
  }) async {
    try {
      // 이메일이 없으면 에러
      if (email.isEmpty) {
        throw Exception('카카오 로그인: 이메일 정보가 없습니다');
      }

      UserCredential? userCredential;

      try {
        // 먼저 이메일로 로그인 시도 (이미 가입된 사용자)
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: _generateTemporaryPassword(email), // 임시 비밀번호
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          // 사용자가 없거나 비밀번호가 틀린 경우 새로 생성
          // 임시 비밀번호 생성 (이메일 기반으로 일관성 유지)
          final tempPassword = _generateTemporaryPassword(email);
          
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: tempPassword,
          );
        } else if (e.code == 'operation-not-allowed') {
          // 이메일/비밀번호 방식이 비활성화된 경우 Anonymous Authentication 사용
          print('이메일/비밀번호 방식이 비활성화되어 있습니다. Anonymous Authentication을 사용합니다.');
          userCredential = await _auth.signInAnonymously();
          
          // Anonymous 사용자에 이메일 연결 (이메일이 검증되지 않음)
          if (userCredential.user != null) {
            await userCredential.user!.updateEmail(email);
          }
        } else {
          rethrow;
        }
      }

      if (userCredential.user != null) {
        // Firestore에 사용자 정보 저장
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? true;
        
        if (isNewUser) {
          // 새 사용자일 경우 Firestore에 저장
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'email': email,
            'displayName': name,
            'photoURL': photoUrl,
            'provider': 'kakao',
            'kakaoId': kakaoId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // 기존 사용자 정보 업데이트
          await _firestore.collection('users').doc(userCredential.user!.uid).update({
            'displayName': name,
            'photoURL': photoUrl,
            'provider': 'kakao',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;
    } catch (e) {
      print('카카오 로그인 오류: $e');
      rethrow;
    }
  }

  // 임시 비밀번호 생성 (이메일 기반으로 일관성 유지)
  // 같은 이메일이면 항상 같은 비밀번호 생성
  String _generateTemporaryPassword(String email) {
    // 이메일을 기반으로 일관된 비밀번호 생성
    // 실제로는 더 복잡한 해시 함수 사용 권장
    final hash = email.hashCode.abs().toString();
    return 'temp_${hash}_naver_kakao';
  }

  // 닉네임 설정 (첫 로그인 시)
  Future<void> setNickname(String nickname) async {
    final user = currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'nickname': nickname,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // 닉네임 중복 체크
  Future<bool> checkNicknameExists(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('nickname', isEqualTo: nickname)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    try {
      await FlutterNaverLogin.logOut(); // 네이버 로그아웃
    } catch (e) {
      // 네이버 로그인을 사용하지 않은 경우 무시
    }
    await _auth.signOut();
  }

  // 비회원 로그인 (임시)
  Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
  }
}

