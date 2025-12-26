import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/app_colors.dart';
import 'auth_provider.dart';
import 'home_screen.dart';
import 'nickname_input_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 닉네임 입력 화면으로 이동
  Future<void> _showNicknameInputDialog(AuthProvider authProvider) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NicknameInputScreen(),
      ),
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
      } else if (provider == 'email') {
        try {
          print('이메일/비밀번호 로그인 시작...');
          success = await authProvider.signInWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text,
          );
          
          // Firestore에서 닉네임 확인
          if (success && authProvider.user != null) {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(authProvider.user!.uid)
                .get();
            isNewUser = !userDoc.exists || userDoc.data()?['nickname'] == null;
          }
        } catch (e, stackTrace) {
          print('이메일/비밀번호 로그인 예외 발생: $e');
          print('스택 트레이스: $stackTrace');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('로그인 실패: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (success) {
        if (isNewUser && (provider == 'google' || provider == 'email')) {
          // 첫 로그인 시 닉네임 입력 화면으로 이동
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
                  // 이메일/비밀번호 로그인
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.none,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      hintText: '이메일을 입력하세요',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.none,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      hintText: '비밀번호를 입력하세요',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 이메일/비밀번호 로그인 버튼
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_emailController.text.trim().isEmpty ||
                                _passwordController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('이메일과 비밀번호를 입력해주세요'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            _handleSocialLogin(authProvider, 'email');
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '이메일로 로그인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 구분선
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[400])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '또는',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 구글 로그인 버튼
                  _buildSocialLoginButton(
                    '구글 로그인',
                    Colors.white,
                    Colors.black87,
                    Icons.g_mobiledata,
                    () => _handleSocialLogin(authProvider, 'google'),
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
