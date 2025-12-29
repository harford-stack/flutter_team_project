import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/app_colors.dart';
import 'auth_provider.dart';

class FindEmailScreen extends StatefulWidget {
  const FindEmailScreen({super.key});

  @override
  State<FindEmailScreen> createState() => _FindEmailScreenState();
}

class _FindEmailScreenState extends State<FindEmailScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final FocusNode _nicknameFocusNode = FocusNode();
  bool _isLoading = false;
  String? _foundEmail;

  @override
  void dispose() {
    _nicknameController.dispose();
    _nicknameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _findEmail(AuthProvider authProvider) async {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('닉네임을 입력해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _foundEmail = null;
    });

    try {
      final email = await authProvider.findEmailByNickname(_nicknameController.text.trim());
      
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _foundEmail = email;
      });

      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('해당 닉네임으로 등록된 이메일을 찾을 수 없습니다'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이메일 찾기 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
        title: const Text(
          '이메일 찾기',
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
              const SizedBox(height: 40),
              const Text(
                '닉네임을 입력하세요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '가입 시 사용한 닉네임을 입력하면\n등록된 이메일을 찾아드립니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nicknameController,
                focusNode: _nicknameFocusNode,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.none,
                enableInteractiveSelection: true,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: '닉네임',
                  hintText: '닉네임을 입력하세요',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _findEmail(authProvider),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _findEmail(authProvider),
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
                        '이메일 찾기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite,
                        ),
                      ),
              ),
              if (_foundEmail != null) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '등록된 이메일',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _foundEmail!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

