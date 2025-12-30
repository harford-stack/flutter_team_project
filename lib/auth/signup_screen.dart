import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/app_colors.dart';
import '../common/password_validator.dart';
import 'auth_provider.dart';
import 'nickname_input_screen.dart';
import 'login_screen.dart';
import 'terms_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  PasswordStrength _passwordStrength = PasswordStrength.weak;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _passwordController.removeListener(_onPasswordChanged);
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _passwordStrength = PasswordValidator.calculateStrength(
        _passwordController.text,
      );
    });
  }

  Future<void> _handleSignUp(AuthProvider authProvider) async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 항목을 입력해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호가 일치하지 않습니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('약관에 동의해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await authProvider.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && authProvider.user != null) {
        if (!mounted) return;
        // 닉네임 입력 화면으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const NicknameInputScreen(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = '회원가입 실패';
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = '이미 사용 중인 이메일입니다';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = '비밀번호가 너무 약합니다. 6자 이상 입력해주세요';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = '올바른 이메일 형식이 아닙니다';
      } else {
        errorMessage = '회원가입 실패: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final passwordRules = PasswordValidator.validateRules(_passwordController.text);
    final ruleTexts = PasswordValidator.getRuleTexts();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    '회원가입',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // 이메일 입력
                  TextField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.none,
                    enableInteractiveSelection: true,
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                    },
                    decoration: InputDecoration(
                      labelText: '이메일',
                      hintText: '이메일을 입력하세요',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/icon_email.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 비밀번호 입력
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.none,
                    enableInteractiveSelection: true,
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
                    },
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      hintText: '비밀번호를 입력하세요',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/icon_password.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
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
                  // 비밀번호 강도 표시
                  if (_passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _passwordStrength == PasswordStrength.weak
                                ? 0.25
                                : _passwordStrength == PasswordStrength.fair
                                    ? 0.5
                                    : _passwordStrength == PasswordStrength.good
                                        ? 0.75
                                        : 1.0,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              PasswordValidator.getStrengthColor(_passwordStrength),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          PasswordValidator.getStrengthText(_passwordStrength),
                          style: TextStyle(
                            color: PasswordValidator.getStrengthColor(_passwordStrength),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 비밀번호 규칙 안내
                    ...List.generate(ruleTexts.length, (index) {
                      final ruleKey = PasswordValidator.getRuleKeys()[index];
                      final isValid = passwordRules[ruleKey] ?? false;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              isValid ? Icons.check_circle : Icons.circle_outlined,
                              size: 16,
                              color: isValid ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              ruleTexts[index],
                              style: TextStyle(
                                fontSize: 12,
                                color: isValid ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 16),
                  // 비밀번호 확인 입력
                  TextField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    obscureText: _obscureConfirmPassword,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.none,
                    enableInteractiveSelection: true,
                    onSubmitted: (_) => _handleSignUp(authProvider),
                    decoration: InputDecoration(
                      labelText: '비밀번호 확인',
                      hintText: '비밀번호를 다시 입력하세요',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/icon_password.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                      errorText: _confirmPasswordController.text.isNotEmpty &&
                              _passwordController.text.isNotEmpty &&
                              _confirmPasswordController.text != _passwordController.text
                          ? '비밀번호가 일치하지 않습니다'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 약관 동의 체크박스
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _agreeToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreeToTerms = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _agreeToTerms = !_agreeToTerms;
                                });
                              },
                              child: const Text(
                                '서비스 이용약관 및 개인정보 처리방침에 동의합니다',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const TermsScreen(type: 'terms'),
                                ),
                              );
                            },
                            child: const Text(
                              '서비스 이용약관 보기',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const TermsScreen(type: 'privacy'),
                                ),
                              );
                            },
                            child: const Text(
                              '개인정보 처리방침 보기',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 회원가입 버튼
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleSignUp(authProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '회원가입',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 로그인 화면으로 이동
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '이미 계정이 있으신가요? ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          '로그인',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

