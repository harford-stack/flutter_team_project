// ============================================
// lib/community/screens/post_editor_screen.dart
// 역할: 게시글 작성 및 수정 화면
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_team_project/common/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../../auth/auth_provider.dart';
import '../../common/custom_appbar.dart';
import '../../common/custom_drawer.dart';
import '../../common/custom_footer.dart';
import '../../recipes/ingreCheck_screen.dart';
import '../../auth/home_screen.dart';
import 'community_list_screen.dart';

/// 게시글 편집기 화면
///
/// 기능:
/// 1. 새 게시글 작성
/// 2. 기존 게시글 수정
/// 3. 이미지 업로드
///
/// 사용 방법:
/// - 새 게시글: PostEditorScreen()
/// - 게시글 수정: PostEditorScreen(existingPost: post)
class PostEditorScreen extends StatefulWidget {
  final Post? existingPost; // 수정 모드일 때 전달되는 기존 게시글

  const PostEditorScreen({
    Key? key,
    this.existingPost,
  }) : super(key: key);

  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends State<PostEditorScreen> {
  /// =====================================================================================
  /// 변수 선언
  /// =====================================================================================
  /// 1. 폼 검증용 키
  final _formKey = GlobalKey<FormState>();

  /// 2. 입력 컨트롤러
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  /// 3. 카테고리
  String _selectedCategory = '자유게시판';
  final List<String> _categories = ['자유게시판', '문의사항'];

  /// 4. 이미지
  File? _imageFile; // 새로 선택한 이미지 파일
  bool _deleteExistingImage = false; // 기존 이미지 삭제 플래그
  final ImagePicker _picker = ImagePicker();

  /// 5. 로딩 상태
  bool _isLoading = false;

  /// 6. 서비스
  final PostService _postService = PostService();

  /// =====================================================================================
  /// 초기화
  /// =====================================================================================
  @override
  void initState() {
    super.initState();

    // 수정 모드인 경우 기존 데이터로 필드 채우기
    if (widget.existingPost != null) {
      _titleController.text = widget.existingPost!.title;
      _contentController.text = widget.existingPost!.content;
      _selectedCategory = widget.existingPost!.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// =====================================================================================
  /// 이미지 처리 함수
  /// =====================================================================================

  /// 갤러리에서 이미지 선택
  ///
  /// 작동 방식:
  /// 1. ImagePicker로 갤러리 열기
  /// 2. 이미지 크기 최적화 (1920x1080, 품질 85%)
  /// 3. 선택된 이미지를 _imageFile에 저장
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _deleteExistingImage = false; // 새 이미지 선택 시 삭제 플래그 해제
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지를 선택할 수 없습니다')),
      );
    }
  }

  /// 이미지 삭제
  ///
  /// 작동 방식:
  /// - 새로 선택한 이미지: _imageFile을 null로
  /// - 기존 이미지: _deleteExistingImage 플래그 설정
  void _removeImage() {
    setState(() {
      _imageFile = null;
      if (widget.existingPost != null &&
          widget.existingPost!.thumbnailUrl.isNotEmpty) {
        _deleteExistingImage = true; // 기존 이미지 삭제 표시
      }
    });
  }

  /// =====================================================================================
  /// 폼 제출 함수
  /// =====================================================================================

  /// 게시글 작성/수정 처리
  ///
  /// 작동 순서:
  /// 1. 폼 유효성 검사
  /// 2. 로그인 상태 확인
  /// 3. 새 게시글 작성 또는 기존 게시글 수정
  /// 4. 성공 시 이전 화면으로 돌아가기
  ///
  /// 에러 처리:
  /// - 이미지 업로드 실패: 에러 메시지 표시 후 재시도 가능
  /// - 네트워크 오류: 상세 에러 메시지 표시
  Future<void> _submitForm() async {
    // 1단계: 폼 유효성 검사
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2단계: 로그인 확인
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool success;

      if (widget.existingPost == null) {
        // ===== 3-1. 새 게시글 작성 =====
        final postId = await _postService.createPost(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          userId: currentUser.uid,
          nickName: authProvider.nickName ?? '익명',
          imageFile: _imageFile,
        );

        success = postId != null;
      } else {
        // ===== 3-2. 기존 게시글 수정 =====
        success = await _postService.updatePost(
          postId: widget.existingPost!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          newImageFile: _imageFile,
          deleteImage: _deleteExistingImage,
        );
      }

      setState(() => _isLoading = false);

      // 4단계: 성공 처리
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.existingPost == null
                  ? '게시글이 작성되었습니다'
                  : '게시글이 수정되었습니다'),
            ),
          );
          Navigator.pop(context, true); // true를 반환하여 목록 새로고침 유도
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글 저장에 실패했습니다')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      // 에러 메시지 상세화
      String errorMessage = '게시글 저장에 실패했습니다';
      if (e.toString().contains('업로드 권한')) {
        errorMessage = '이미지 업로드 권한이 없습니다. Firebase Storage 규칙을 확인해주세요.';
      } else if (e.toString().contains('용량')) {
        errorMessage = 'Storage 용량이 초과되었습니다.';
      } else if (e.toString().contains('이미지')) {
        errorMessage = '이미지 업로드에 실패했습니다. 다시 시도해주세요.';
      } else if (e.toString().isNotEmpty) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// =====================================================================================
  /// 네비게이션 처리
  /// =====================================================================================

  /// 하단 네비게이션 바 탭 처리
  void _handleFooterTap(int index) {
    if (index == 2) {
      // 커뮤니티 탭
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityListScreen(
            showAppBarAndFooter: true,
          ),
        ),
      );
    } else if (index == 1) {
      // 냉장고 탭
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => IngrecheckScreen()),
      );
    } else if (index == 0) {
      // 홈 탭
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('해당 기능은 개발 중입니다')),
      );
    }
  }

  /// =====================================================================================
  /// UI 구현
  /// =====================================================================================
  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingPost != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        appName: isEditMode ? '게시글 수정' : '게시글 작성',
      ),
      drawer: CustomDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24),

              // 1. 카테고리 선택
              _buildCategorySelector(),
              SizedBox(height: 16),

              // 2. 제목 입력
              _buildTitleField(),
              SizedBox(height: 16),

              // 3. 내용 입력
              _buildContentField(),
              SizedBox(height: 16),

              // 4. 이미지 선택
              _buildImageSection(),
              SizedBox(height: 24),

              // 5. 제출 버튼
              _buildSubmitButton(isEditMode),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomFooter(
        currentIndex: 2,
        onTap: _handleFooterTap,
      ),
    );
  }

  /// =====================================================================================
  /// 위젯 빌더들
  /// =====================================================================================

  /// 1. 카테고리 선택기
  ///
  /// 기능:
  /// - 여러 카테고리 중 하나를 선택
  /// - ChoiceChip으로 시각적 표현
  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '카테고리',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.secondaryColor,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;
            return ChoiceChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primaryColor,
              backgroundColor: Colors.white,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 2. 제목 입력 필드
  ///
  /// 검증:
  /// - 빈 값 불가
  /// - 최대 100자
  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      cursorColor: AppColors.primaryColor,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: '제목',
        hintText: '게시글 제목을 입력하세요',
        labelStyle: TextStyle(color: Colors.grey),
        floatingLabelStyle: TextStyle(color: AppColors.secondaryColor),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.secondaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
        ),
      ),
      maxLength: 100,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '제목을 입력하세요';
        }
        return null;
      },
    );
  }

  /// 3. 내용 입력 필드
  ///
  /// 검증:
  /// - 빈 값 불가
  /// - 최대 5000자
  /// - 여러 줄 입력 가능
  Widget _buildContentField() {
    return TextFormField(
      controller: _contentController,
      cursorColor: AppColors.primaryColor,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: '내용',
        hintText: '게시글 내용을 입력하세요',
        alignLabelWithHint: true,
        labelStyle: TextStyle(color: Colors.grey),
        floatingLabelStyle: TextStyle(color: AppColors.secondaryColor),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.secondaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
        ),
      ),
      maxLines: 10,
      maxLength: 5000,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '내용을 입력하세요';
        }
        return null;
      },
    );
  }

  /// 4. 이미지 섹션
  ///
  /// 기능:
  /// - 이미지 미리보기 (새 이미지 또는 기존 이미지)
  /// - 이미지 선택/변경 버튼
  /// - 이미지 삭제 버튼 (X 아이콘)
  Widget _buildImageSection() {
    final hasExistingImage = widget.existingPost != null &&
        widget.existingPost!.thumbnailUrl.isNotEmpty;
    final showExistingImage = hasExistingImage &&
        _imageFile == null &&
        !_deleteExistingImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이미지 (선택사항)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.secondaryColor,
          ),
        ),
        SizedBox(height: 8),

        // 이미지 미리보기
        if (_imageFile != null || showExistingImage)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // 이미지 표시
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity)
                      : Image.network(
                    widget.existingPost!.thumbnailUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
                // 삭제 버튼
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    onPressed: _removeImage,
                  ),
                ),
              ],
            ),
          ),

        SizedBox(height: 8),

        // 이미지 선택/변경 버튼
        OutlinedButton.icon(
          onPressed: _pickImage,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            side: BorderSide(
              color: AppColors.primaryColor,
              width: 1.5,
            ),
          ),
          icon: Icon(Icons.image),
          label: Text(_imageFile != null || showExistingImage
              ? '이미지 변경'
              : '이미지 선택'),
        ),
      ],
    );
  }

  /// 5. 제출 버튼
  Widget _buildSubmitButton(bool isEditMode) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          isEditMode ? '수정 완료' : '작성 완료',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}