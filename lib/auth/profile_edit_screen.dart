import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/app_colors.dart';
import 'auth_provider.dart';
import 'change_password_screen.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final FocusNode _nicknameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _nicknameFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final profile = await authProvider.getUserProfile();
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _nicknameController.text = profile['nickname'] ?? '';
          _emailController.text = profile['email'] ?? authProvider.user?.email ?? '';
          _selectedGender = profile['gender'];
          if (profile['birthDate'] != null) {
            _selectedBirthDate = (profile['birthDate'] as Timestamp).toDate();
            _birthDateController.text = 
                '${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}';
          }
          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _emailController.text = authProvider.user?.email ?? '';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 로드 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = 
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _handleUpdateProfile(AuthProvider authProvider) async {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('닉네임을 입력해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 닉네임이 변경되었는지 확인
    final currentNickname = _userProfile?['nickname'] ?? '';
    if (_nicknameController.text.trim() != currentNickname) {
      // 닉네임 중복 체크
      final nicknameExists = await authProvider.checkNicknameExists(
        _nicknameController.text.trim(),
      );
      if (nicknameExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미 사용 중인 닉네임입니다'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updateData = <String, dynamic>{
        'nickname': _nicknameController.text.trim(),
      };

      if (_selectedBirthDate != null) {
        updateData['birthDate'] = Timestamp.fromDate(_selectedBirthDate!);
      }

      if (_selectedGender != null) {
        updateData['gender'] = _selectedGender;
      }

      await authProvider.updateUserProfile(updateData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로필이 업데이트되었습니다'),
          backgroundColor: AppColors.primaryColor,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('프로필 업데이트 실패: ${e.toString()}'),
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

  Future<void> _handleUpdateEmail(AuthProvider authProvider) async {
    final newEmail = _emailController.text.trim();
    if (newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이메일을 입력해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 이메일 형식 검증
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(newEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('올바른 이메일 형식을 입력해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 현재 이메일과 같은지 확인
    final currentEmail = authProvider.user?.email ?? '';
    if (newEmail == currentEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('현재 이메일과 동일합니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 비밀번호 입력 다이얼로그
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이메일 변경'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('이메일 변경을 위해 현재 비밀번호를 입력해주세요'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed != true || passwordController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await authProvider.updateEmail(newEmail, passwordController.text);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이메일 변경 확인 링크를 전송했습니다. 이메일을 확인해주세요.'),
          backgroundColor: AppColors.primaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = '이메일 변경 실패';
      if (e.toString().contains('wrong-password') ||
          e.toString().contains('invalid-credential')) {
        errorMessage = '비밀번호가 올바르지 않습니다';
      } else if (e.toString().contains('email-already-in-use')) {
        errorMessage = '이미 사용 중인 이메일입니다';
      } else {
        errorMessage = '이메일 변경 실패: ${e.toString()}';
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

    if (_isLoadingProfile) {
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
            '프로필 수정',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
          '프로필 수정',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // 닉네임 입력
              TextField(
                controller: _nicknameController,
                focusNode: _nicknameFocusNode,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.none,
                enableInteractiveSelection: true,
                enabled: !_isLoading,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: '닉네임',
                  hintText: '닉네임을 입력하세요',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              // 이메일 입력
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.none,
                      enableInteractiveSelection: true,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: '이메일',
                        hintText: '이메일을 입력하세요',
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(Icons.email),
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _handleUpdateEmail(authProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    child: const Text(
                      '변경',
                      style: TextStyle(color: AppColors.textWhite),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 생년월일 입력
              TextField(
                controller: _birthDateController,
                readOnly: true,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: '생년월일',
                  hintText: '생년월일을 선택하세요',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(Icons.calendar_today),
                  ),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: _isLoading ? null : _selectBirthDate,
                  ),
                ),
                onTap: _isLoading ? null : _selectBirthDate,
              ),
              const SizedBox(height: 16),
              // 성별 선택
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: '성별',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(Icons.person),
                  ),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('남성')),
                  DropdownMenuItem(value: 'female', child: Text('여성')),
                  DropdownMenuItem(value: 'other', child: Text('기타')),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
              ),
              const SizedBox(height: 32),
              // 비밀번호 변경 버튼
              OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[400]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '비밀번호 변경',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 프로필 저장 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : () => _handleUpdateProfile(authProvider),
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
                        '프로필 저장',
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

