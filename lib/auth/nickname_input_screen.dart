import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/app_colors.dart';
import 'auth_provider.dart';
import 'home_screen.dart';

class NicknameInputScreen extends StatefulWidget {
  const NicknameInputScreen({super.key});

  @override
  State<NicknameInputScreen> createState() => _NicknameInputScreenState();
}

class _NicknameInputScreenState extends State<NicknameInputScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final FocusNode _nicknameFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 화면이 로드된 후 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _nicknameFocusNode.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nicknameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(AuthProvider authProvider) async {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 닉네임 중복 체크
      final nicknameExists =
          await authProvider.checkNicknameExists(_nicknameController.text.trim());

      if (nicknameExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('이미 사용 중인 닉네임입니다. 다시 입력해주세요.')),
        );
      } else {
        await authProvider.setNickname(_nicknameController.text.trim());
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원가입 완료'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      }
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                '닉네임 입력',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '사용할 닉네임을 입력해주세요',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _nicknameController,
                focusNode: _nicknameFocusNode,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.none,
                enableInteractiveSelection: true,
                enabled: !_isLoading,
                maxLength: 20,
                decoration: const InputDecoration(
                  hintText: '닉네임을 입력하세요',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                onSubmitted: (_) => _handleSubmit(authProvider),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _handleSubmit(authProvider),
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
                        '확인',
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

