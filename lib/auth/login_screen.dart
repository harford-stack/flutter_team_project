import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_account_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import '../common/app_colors.dart';
import 'auth_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  // 닉네임 입력 다이얼로그
  Future<void> _showNicknameInputDialog(AuthProvider authProvider) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('닉네임 입력'),
          content: TextField(
            controller: _nicknameController,
            decoration: const InputDecoration(
              hintText: '닉네임을 입력하세요',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('확인'),
              onPressed: () async {
                if (_nicknameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('닉네임을 입력해주세요')),
                  );
                  return;
                }

                // 닉네임 중복 체크
                final nicknameExists =
                    await authProvider.checkNicknameExists(
                        _nicknameController.text.trim());

                if (nicknameExists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('이미 사용 중인 닉네임입니다. 다시 입력해주세요.')),
                  );
                } else {
                  await authProvider.setNickname(_nicknameController.text.trim());
                  Navigator.of(context).pop();
                  _handleLoginSuccess(authProvider, '회원가입');
                }
              },
            ),
          ],
        );
      },
    );
  }

  // 로그인 성공 처리
  void _handleLoginSuccess(AuthProvider authProvider, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type 완료'),
        backgroundColor: AppColors.primaryColor,
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  // 소셜 로그인 버튼 처리
  Future<void> _handleSocialLogin(
      AuthProvider authProvider, String provider) async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success = false;
      bool isNewUser = false;

      if (provider == 'google') {
        success = await authProvider.signInWithGoogle();
        // Firestore에서 닉네임 확인
        if (success && authProvider.user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(authProvider.user!.uid)
              .get();
          isNewUser = !userDoc.exists || userDoc.data()?['nickname'] == null;
        }
      } else if (provider == 'naver') {
        try {
          print('네이버 로그인 시작...');
          // 네이버 SDK로 로그인 (최신 버전 API)
          final NaverLoginResult loginResult = await FlutterNaverLogin.logIn().timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              print('네이버 로그인 타임아웃');
              return NaverLoginResult(
                status: NaverLoginStatus.error,
                errorMessage: '로그인 시간이 초과되었습니다.',
              );
            },
          );
          print('네이버 로그인 결과: status=${loginResult.status}, errorMessage=${loginResult.errorMessage}');
          print('네이버 로그인 결과 상세: accessToken=${loginResult.accessToken}, account=${loginResult.account}');
          
          // 로그인 성공 확인
          if (loginResult.status == NaverLoginStatus.loggedIn) {
            print('네이버 로그인 성공');
            // NaverLoginResult에 이미 account가 포함되어 있음
            final account = loginResult.account;
            print('네이버 계정 정보: account=${account?.email}');
            
            if (account != null) {
              // 이메일이 없으면 에러
              if (account.email == null || account.email!.isEmpty) {
                throw Exception('네이버 로그인: 이메일 정보가 없습니다. 네이버 계정 설정에서 이메일 제공을 허용해주세요.');
              }
              
              // AuthProvider를 통해 Firebase에 사용자 생성 및 Firestore 저장
              success = await authProvider.signInWithNaver(
                email: account.email!,
                name: account.name ?? account.nickname ?? '네이버 사용자',
                photoUrl: account.profileImage,
                naverId: account.id,
              );
              
              // Firestore에서 닉네임 확인
              if (success && authProvider.user != null) {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(authProvider.user!.uid)
                    .get();
                isNewUser = !userDoc.exists || userDoc.data()?['nickname'] == null;
              }
            } else {
              // account가 없으면 getCurrentAccount()로 다시 시도
              final NaverAccountResult accountResult = await FlutterNaverLogin.getCurrentAccount();
              
              // 이메일이 없으면 에러
              if (accountResult.email == null || accountResult.email!.isEmpty) {
                throw Exception('네이버 로그인: 이메일 정보가 없습니다. 네이버 계정 설정에서 이메일 제공을 허용해주세요.');
              }
              
              // AuthProvider를 통해 Firebase에 사용자 생성 및 Firestore 저장
              success = await authProvider.signInWithNaver(
                email: accountResult.email!,
                name: accountResult.name ?? accountResult.nickname ?? '네이버 사용자',
                photoUrl: accountResult.profileImage,
                naverId: accountResult.id,
              );
              
              // Firestore에서 닉네임 확인
              if (success && authProvider.user != null) {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(authProvider.user!.uid)
                    .get();
                isNewUser = !userDoc.exists || userDoc.data()?['nickname'] == null;
              }
            }
          } else {
            // 사용자가 로그인 취소 또는 오류
            print('네이버 로그인 실패 또는 취소: status=${loginResult.status}, errorMessage=${loginResult.errorMessage}');
            success = false;
            if (loginResult.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('네이버 로그인 실패: ${loginResult.errorMessage}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e, stackTrace) {
          print('네이버 로그인 예외 발생: $e');
          print('스택 트레이스: $stackTrace');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('네이버 로그인 실패: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } else if (provider == 'kakao') {
        try {
          // 카카오 로그인은 아직 구현되지 않음
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('카카오 로그인은 추후 구현 예정입니다'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('카카오 로그인은 추후 구현 예정입니다'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      if (success) {
        if (isNewUser && (provider == 'google' || provider == 'naver')) {
          // 첫 로그인 시 닉네임 입력
          _nicknameController.clear();
          await _showNicknameInputDialog(authProvider);
        } else {
          _handleLoginSuccess(authProvider, '로그인');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  // 상단 텍스트 "로그인"
                  const Text(
                    '로그인',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // 서브 텍스트
                  const Text(
                    '로그인하고 나만의 냉장고와 레시피를 관리하세요',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // 두 개의 박스 (냉장고 아이콘 + 북마크 아이콘)
                  Row(
                    children: [
                      // 냉장고 박스
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.kitchen,
                                size: 40,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '나의 냉장고\n재료 저장',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 가운데 세로선
                      Container(
                        width: 1,
                        height: 100,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      // 북마크 박스
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.bookmark,
                                size: 40,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '내 레시피 저장과\n북마크',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // 구글 로그인 버튼
                  _buildSocialLoginButton(
                    '구글 로그인',
                    Colors.white,
                    Colors.black87,
                    Icons.g_mobiledata,
                    () => _handleSocialLogin(authProvider, 'google'),
                  ),
                  const SizedBox(height: 12),
                  // 네이버 로그인 버튼
                  _buildSocialLoginButton(
                    '네이버 로그인',
                    const Color(0xFF03C75A),
                    Colors.white,
                    Icons.account_circle,
                    () => _handleSocialLogin(authProvider, 'naver'),
                  ),
                  const SizedBox(height: 12),
                  // 카카오 로그인 버튼
                  _buildSocialLoginButton(
                    '카카오 로그인',
                    const Color(0xFFFEE500),
                    Colors.black87,
                    Icons.chat_bubble,
                    () => _handleSocialLogin(authProvider, 'kakao'),
                  ),
                  const SizedBox(height: 24),
                  // 안내 문구
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      '로그인 후 이용하시면 내 냉장고 재료 저장, 북마크, 레시피 저장, 커뮤니티 등 다양한 기능을 이용 가능합니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 비회원 로그인 버튼
                  OutlinedButton(
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        await authProvider.signInAnonymously();
                        _handleLoginSuccess(authProvider, '비회원 로그인');
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('로그인 실패: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '비회원 로그인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSocialLoginButton(
    String text,
    Color backgroundColor,
    Color textColor,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
