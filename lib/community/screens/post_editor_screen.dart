import 'package:flutter/material.dart';
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

/// 帖子编辑器页面
/// 支持创建新帖子和编辑现有帖子
class PostEditorScreen extends StatefulWidget {
  final Post? existingPost; // 如果是编辑模式，传入现有帖子

  const PostEditorScreen({
    Key? key,
    this.existingPost,
  }) : super(key: key);

  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends State<PostEditorScreen> {
  /// ========== 变量声明 ==========
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _selectedCategory = '자유게시판';
  File? _imageFile;
  bool _isLoading = false;
  bool _deleteExistingImage = false;

  final List<String> _categories = ['자유게시판', '문의사항'];
  final ImagePicker _picker = ImagePicker();
  final PostService _postService = PostService();

  /// ========== 初始化 ==========
  @override
  void initState() {
    super.initState();

    // 如果是编辑模式，填充现有数据
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

  /// ========== 选择图片 ==========
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
          _deleteExistingImage = false; // 选择新图片时取消删除标记
        });
      }
    } catch (e) {
      print('이미지 선택 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지를 선택할 수 없습니다')),
      );
    }
  }

  /// ========== 删除图片 ==========
  void _removeImage() {
    setState(() {
      _imageFile = null;
      if (widget.existingPost != null &&
          widget.existingPost!.thumbnailUrl.isNotEmpty) {
        _deleteExistingImage = true; // 标记删除现有图片
      }
    });
  }

  /// ========== 提交表单 ==========
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
        // ===== 创建新帖子 =====
        final postId = await _postService.createPost(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          userId: currentUser.uid,
          nickName: currentUser.displayName ?? '익명',
          imageFile: _imageFile,
        );

        success = postId != null;
      } else {
        // ===== 编辑现有帖子 =====
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

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.existingPost == null
                  ? '게시글이 작성되었습니다'
                  : '게시글이 수정되었습니다'),
            ),
          );
          Navigator.pop(context, true); // 返回并标记成功
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글 저장에 실패했습니다')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('게시글 저장 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다')),
      );
    }
  }
  /// ========== bottomnavbar ==========
  void _handleFooterTap(int index) {
    if (index == 2) {
      Navigator.pop(context);
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => IngrecheckScreen()),
      );
    } else if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('해당 기능은 개발 중입니다')),
      );
    }
  }



  /// ========== UI 构建 ==========
  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingPost != null;

    return Scaffold(
      appBar: CustomAppBar(),
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
              // 标题
              Text(
                isEditMode ? '게시글 수정' : '게시글 작성',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),

              // 分类选择
              _buildCategorySelector(),
              SizedBox(height: 16),

              // 标题输入
              _buildTitleField(),
              SizedBox(height: 16),

              // 内容输入
              _buildContentField(),
              SizedBox(height: 16),

              // 图片选择
              _buildImageSection(),
              SizedBox(height: 24),

              // 提交按钮
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

  /// 分类选择器
  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '카테고리',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;
            return ChoiceChip(
              label: Text(category),
              selected: isSelected,
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

  /// 标题输入框
  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: '제목',
        hintText: '게시글 제목을 입력하세요',
        border: OutlineInputBorder(),
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

  /// 内容输入框
  Widget _buildContentField() {
    return TextFormField(
      controller: _contentController,
      decoration: InputDecoration(
        labelText: '내용',
        hintText: '게시글 내용을 입력하세요',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
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

  /// 图片选择区域
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
          ),
        ),
        SizedBox(height: 8),

        // 显示图片预览
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
                // 图片
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
                // 删除按钮
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

        // 选择图片按钮
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: Icon(Icons.image),
          label: Text(_imageFile != null || showExistingImage
              ? '이미지 변경'
              : '이미지 선택'),
        ),
      ],
    );
  }

  /// 提交按钮
  Widget _buildSubmitButton(bool isEditMode) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          isEditMode ? '수정 완료' : '작성 완료',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}