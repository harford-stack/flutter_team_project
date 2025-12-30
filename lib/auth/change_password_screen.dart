import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/app_colors.dart';
import '../common/password_validator.dart';
import 'auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _currentPasswordFocusNode = FocusNode();
  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  PasswordStrength _passwordStrength = PasswordStrength.weak;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _newPasswordController.removeListener(_onPasswordChanged);
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _passwordStrength = PasswordValidator.calculateStrength(
        _newPasswordController.text,
      );
    });
  }

  Future<void> _handleChangePassword(AuthProvider authProvider) async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 항목을 입력해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('새 비밀번호가 일치하지 않습니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentPasswordController.text == _newPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('현재 비밀번호와 새 비밀번호가 같습니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await authProvider.updatePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호가 변경되었습니다'),
          backgroundColor: AppColors.primaryColor,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      String errorMessage = '비밀번호 변경 실패';
      if (e.toString().contains('wrong-password') ||
          e.toString().contains('invalid-credential')) {
        errorMessage = '현재 비밀번호가 올바르지 않습니다';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = '비밀번호가 너무 약합니다. 6자 이상 입력해주세요';
      } else {
        errorMessage = '비밀번호 변경 실패: ${e.toString()}';
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
    final passwordRules = PasswordValidator.validateRules(_newPasswordController.text);
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
        title: const Text(
          '비밀번호 변경',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // 현재 비밀번호 입력
              TextField(
                controller: _currentPasswordController,
                focusNode: _currentPasswordFocusNode,
                obscureText: _obscureCurrentPassword,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.none,
                enableInteractiveSelection: true,
                enabled: !_isLoading,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_newPasswordFocusNode);
                },
                decoration: InputDecoration(
                  labelText: '현재 비밀번호',
                  hintText: '현재 비밀번호를 입력하세요',
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
                      _obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // 새 비밀번호 입력
              TextField(
                controller: _newPasswordController,
                focusNode: _newPasswordFocusNode,
                obscureText: _obscureNewPassword,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.none,
                enableInteractiveSelection: true,
                enabled: !_isLoading,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
                },
                decoration: InputDecoration(
                  labelText: '새 비밀번호',
                  hintText: '새 비밀번호를 입력하세요',
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
                      _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              // 비밀번호 강도 표시
              if (_newPasswordController.text.isNotEmpty) ...[
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
              // 새 비밀번호 확인 입력
              TextField(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocusNode,
                obscureText: _obscureConfirmPassword,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.none,
                enableInteractiveSelection: true,
                enabled: !_isLoading,
                onSubmitted: (_) => _handleChangePassword(authProvider),
                decoration: InputDecoration(
                  labelText: '새 비밀번호 확인',
                  hintText: '새 비밀번호를 다시 입력하세요',
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
                          _newPasswordController.text.isNotEmpty &&
                          _confirmPasswordController.text != _newPasswordController.text
                      ? '비밀번호가 일치하지 않습니다'
                      : null,
                ),
              ),
              const SizedBox(height: 32),
              // 비밀번호 변경 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : () => _handleChangePassword(authProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '비밀번호 변경',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

