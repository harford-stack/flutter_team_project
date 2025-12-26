import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

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


  // 이메일/비밀번호 로그인 (회원가입 페이지 없이 자동 처리)
  // 사용자가 없으면 자동으로 회원가입
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential? userCredential;

      try {
        // 먼저 로그인 시도
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || 
            e.code == 'wrong-password' || 
            e.code == 'invalid-credential') {
          // 사용자가 없거나 비밀번호가 틀린 경우 회원가입 시도
          try {
            userCredential = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } on FirebaseAuthException catch (createError) {
            if (createError.code == 'email-already-in-use') {
              // 이미 가입된 이메일인 경우 비밀번호가 틀린 것으로 판단
              throw Exception('비밀번호가 올바르지 않습니다. 다시 확인해주세요.');
            } else if (createError.code == 'weak-password') {
              throw Exception('비밀번호가 너무 약합니다. 6자 이상 입력해주세요.');
            } else if (createError.code == 'invalid-email') {
              throw Exception('올바른 이메일 형식이 아닙니다.');
            } else {
              rethrow;
            }
          }
        } else if (e.code == 'invalid-email') {
          throw Exception('올바른 이메일 형식이 아닙니다.');
        } else if (e.code == 'user-disabled') {
          throw Exception('이 계정은 비활성화되었습니다.');
        } else if (e.code == 'too-many-requests') {
          throw Exception('너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.');
        } else {
          rethrow;
        }
      }

      if (userCredential != null && userCredential.user != null) {
        // 첫 로그인인지 확인
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        if (isNewUser) {
          // 새 사용자일 경우 Firestore에 사용자 정보 저장
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'email': email,
            'displayName': email.split('@')[0], // 이메일의 @ 앞부분을 기본 이름으로
            'provider': 'email',
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // 기존 사용자 정보 업데이트
          await _firestore.collection('users').doc(userCredential.user!.uid).update({
            'provider': 'email',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;
    } catch (e) {
      print('이메일/비밀번호 로그인 오류: $e');
      rethrow;
    }
  }

  // 임시 비밀번호 생성 (이메일 기반으로 일관성 유지)
  // 같은 이메일이면 항상 같은 비밀번호 생성
  String _generateTemporaryPassword(String email) {
    // 이메일을 기반으로 일관된 비밀번호 생성
    // 실제로는 더 복잡한 해시 함수 사용 권장
    final hash = email.hashCode.abs().toString();
    return 'temp_${hash}';
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
    await _auth.signOut();
  }

  // 비회원 로그인 (임시)
  Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
  }
}

