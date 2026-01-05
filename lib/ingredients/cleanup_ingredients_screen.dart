// Firestore 재료 목록 정리 화면
// 중복 재료 삭제 및 일반 재료만 남기기

import 'package:flutter/material.dart';
import 'cleanup_ingredients_script.dart';
import '../common/app_colors.dart';

class CleanupIngredientsScreen extends StatefulWidget {
  const CleanupIngredientsScreen({super.key});

  @override
  State<CleanupIngredientsScreen> createState() => _CleanupIngredientsScreenState();
}

class _CleanupIngredientsScreenState extends State<CleanupIngredientsScreen> {
  final CleanupIngredientsScript _script = CleanupIngredientsScript();
  bool _isLoading = false;
  String _statusMessage = '';
  String _detailsMessage = '';

  Future<void> _removeDuplicates() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '중복 재료 찾는 중...';
      _detailsMessage = '';
    });

    try {
      await _script.removeDuplicates();
      setState(() {
        _statusMessage = '중복 재료 삭제 완료!';
        _detailsMessage = '콘솔에서 상세 정보를 확인하세요.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '에러 발생: $e';
        _detailsMessage = '';
        _isLoading = false;
      });
    }
  }

  Future<void> _keepOnlyCommon() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '일반 재료만 남기는 중...';
      _detailsMessage = '';
    });

    try {
      await _script.keepOnlyCommonIngredients();
      setState(() {
        _statusMessage = '일반 재료만 남기기 완료!';
        _detailsMessage = '콘솔에서 상세 정보를 확인하세요.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '에러 발생: $e';
        _detailsMessage = '';
        _isLoading = false;
      });
    }
  }

  Future<void> _replaceAll() async {
    // 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('경고'),
        content: const Text(
          '기존 재료를 모두 삭제하고 일반 재료로 교체합니다.\n'
          '이 작업은 되돌릴 수 없습니다.\n\n'
          '정말 진행하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('진행'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '재료 목록 전체 교체 중...';
      _detailsMessage = '';
    });

    try {
      await _script.replaceWithCommonIngredients();
      setState(() {
        _statusMessage = '재료 목록 교체 완료!';
        _detailsMessage = '콘솔에서 상세 정보를 확인하세요.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '에러 발생: $e';
        _detailsMessage = '';
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanupAll() async {
    // 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('확인'),
        content: const Text(
          '중복 재료를 삭제하고 일반 재료만 남깁니다.\n\n'
          '진행하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('진행'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '재료 목록 정리 중...';
      _detailsMessage = '';
    });

    try {
      await _script.cleanupAll();
      setState(() {
        _statusMessage = '재료 목록 정리 완료!';
        _detailsMessage = '콘솔에서 상세 정보를 확인하세요.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '에러 발생: $e';
        _detailsMessage = '';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('재료 목록 정리 (관리자)'),
        backgroundColor: AppColors.backgroundColor,
        foregroundColor: AppColors.textDark,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('완료') || _statusMessage.contains('교체')
                      ? Colors.green.shade100
                      : _statusMessage.contains('에러')
                          ? Colors.red.shade100
                          : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _statusMessage.contains('완료') || _statusMessage.contains('교체')
                            ? Colors.green.shade900
                            : _statusMessage.contains('에러')
                                ? Colors.red.shade900
                                : Colors.blue.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_detailsMessage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _detailsMessage,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '작업 옵션',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildOptionButton(
                      title: '1. 중복 재료만 삭제',
                      description: '같은 이름의 재료 중 첫 번째만 남기고 나머지 삭제',
                      onPressed: _isLoading ? null : _removeDuplicates,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildOptionButton(
                      title: '2. 일반 재료만 남기기',
                      description: '일반 가정에서 자주 사용하는 재료만 유지하고 나머지 삭제',
                      onPressed: _isLoading ? null : _keepOnlyCommon,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildOptionButton(
                      title: '3. 통합 정리 (권장)',
                      description: '중복 제거 + 일반 재료만 남기기',
                      onPressed: _isLoading ? null : _cleanupAll,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildOptionButton(
                      title: '4. 전체 교체 (주의)',
                      description: '기존 재료 모두 삭제 후 일반 재료만 추가',
                      onPressed: _isLoading ? null : _replaceAll,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '주의사항',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• 작업 진행 중에는 앱을 종료하지 마세요\n'
                      '• "전체 교체" 옵션은 되돌릴 수 없습니다\n'
                      '• 작업 결과는 콘솔 로그에서 확인할 수 있습니다\n'
                      '• 일반 재료 목록은 코드에서 수정 가능합니다',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String title,
    required String description,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        alignment: Alignment.centerLeft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

