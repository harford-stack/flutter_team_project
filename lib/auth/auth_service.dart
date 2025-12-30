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

      if (userCredential.user != null) {
        // Firestore 문서 확인 및 생성/업데이트
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        // 첫 로그인인지 확인
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        if (isNewUser || !userDoc.exists) {
          // 새 사용자이거나 Firestore 문서가 없으면 생성
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'displayName': userCredential.user!.displayName,
            'photoURL': userCredential.user!.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // 기존 사용자 정보 업데이트
          await _firestore.collection('users').doc(userCredential.user!.uid).update({
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;
    } catch (e) {
      print('구글 로그인 오류: $e');
      rethrow;
    }
  }


  // 이메일/비밀번호 로그인 (로그인만 처리, 회원가입은 별도 화면에서)
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // 로그인 시도
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Firestore 문서 확인 및 생성/업데이트
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // Firestore 문서가 없으면 생성 (이전에 수동 삭제된 경우 대비)
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'email': email,
            'displayName': email.split('@')[0],
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
    } on FirebaseAuthException catch (e) {
      // 에러 메시지 한글화
      if (e.code == 'user-not-found') {
        throw Exception('등록되지 않은 이메일입니다. 회원가입을 먼저 진행해주세요.');
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('비밀번호가 올바르지 않습니다. 다시 확인해주세요.');
      } else if (e.code == 'invalid-email') {
        throw Exception('올바른 이메일 형식이 아닙니다.');
      } else if (e.code == 'user-disabled') {
        throw Exception('이 계정은 비활성화되었습니다.');
      } else if (e.code == 'too-many-requests') {
        throw Exception('너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.');
      } else {
        throw Exception('로그인 실패: ${e.message}');
      }
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

  // 계정 삭제
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    try {
      final uid = user.uid;
      
      // Firestore에서 사용자 데이터 삭제
      await _firestore.collection('users').doc(uid).delete();
      
      // Firebase Auth에서 계정 삭제
      await user.delete();
      
      // Google 로그인도 로그아웃
      await _googleSignIn.signOut();
    } catch (e) {
      print('계정 삭제 오류: $e');
      rethrow;
    }
  }

  // 닉네임으로 이메일 찾기
  Future<String?> findEmailByNickname(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        return userData['email'] as String?;
      }
      return null;
    } catch (e) {
      print('이메일 찾기 오류: $e');
      rethrow;
    }
  }

  // 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('비밀번호 재설정 이메일 전송 오류: $e');
      rethrow;
    }
  }

  // 사용자 프로필 조회
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('프로필 조회 오류: $e');
      rethrow;
    }
  }

  // 사용자 프로필 업데이트
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(user.uid).update(data);
    } catch (e) {
      print('프로필 업데이트 오류: $e');
      rethrow;
    }
  }

  // 이메일 변경 (재인증 필요)
  Future<void> updateEmail(String newEmail, String password) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    try {
      // 재인증
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // 이메일 변경
      await user.verifyBeforeUpdateEmail(newEmail);

      // Firestore 업데이트
      await _firestore.collection('users').doc(user.uid).update({
        'email': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('이메일 변경 오류: $e');
      rethrow;
    }
  }

  // 비밀번호 변경
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    try {
      // 재인증
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // 비밀번호 변경
      await user.updatePassword(newPassword);
    } catch (e) {
      print('비밀번호 변경 오류: $e');
      rethrow;
    }
  }

  // 이메일/비밀번호로 회원가입 (별도 회원가입용)
  Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Firestore에 사용자 정보 저장
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'displayName': email.split('@')[0],
          'provider': 'email',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      print('회원가입 오류: $e');
      rethrow;
    }
  }
}

