// ==================================================================================
// 3. list_bottom_actions.dart - 하단 액션바 (공유 컴포넌트)
// ==================================================================================
// community/widgets/shared/list_bottom_actions.dart

import 'package:flutter/material.dart';
import '../../../common/app_colors.dart';

/// 하단 액션바 타입
enum ListActionType {
  bookmark, // 북마크 해제
  deletePost, // 게시글 삭제
}

/// 통합 하단 액션바 컴포넌트
/// 사용처: 북마크 목록, 내 게시글 목록
class ListBottomActions extends StatelessWidget {
  /// =====================================================================================
  /// 필드
  /// =====================================================================================
  final ListActionType actionType; // 액션 타입
  final bool isSelectionMode; // 선택 모드 여부
  final int selectedCount; // 선택된 항목 수
  final VoidCallback onPrimaryAction; // 주 액션 콜백 (삭제/해제)
  final VoidCallback onSecondaryAction; // 보조 액션 콜백 (취소/돌아가기)

  const ListBottomActions({
    Key? key,
    required this.actionType,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  }) : super(key: key);

  /// =====================================================================================
  /// UI 구현
  /// =====================================================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 왼쪽 버튼: 주 액션 (삭제/해제)
          Expanded(
            child: ElevatedButton(
              // 중요: 버튼은 항상 활성화 (내부 로직에서 처리)
              onPressed: onPrimaryAction,
              style: ElevatedButton.styleFrom(
                // 중요: 선택 모드 + 선택된 항목 있을 때만 빨간색
                backgroundColor: _getButtonColor(),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _getPrimaryButtonText(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),

          // 오른쪽 버튼: 보조 액션 (취소/돌아가기)
          Expanded(
            child: OutlinedButton(
              onPressed: onSecondaryAction,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isSelectionMode ? '취소' : '돌아가기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =====================================================================================
  /// 헬퍼 함수들
  /// =====================================================================================
  /// 주 버튼 배경색 결정
  /// 중요: 선택 모드 + 선택된 항목이 있을 때만 빨간색 (위험한 작업 강조)
  Color _getButtonColor() {
    if (isSelectionMode && selectedCount > 0) {
      return Colors.red; // 삭제/해제 작업 시 위험 표시
    }
    return AppColors.primaryColor; // 기본 상태
  }

  /// 주 버튼 텍스트 결정
  String _getPrimaryButtonText() {
    if (isSelectionMode) {
      if (selectedCount == 0) {
        // 선택 모드이지만 선택된 항목이 없을 때
        return actionType == ListActionType.bookmark
            ? '삭제할 항목 선택'
            : '삭제할 게시글 선택';
      } else {
        // 선택 모드이고 선택된 항목이 있을 때
        return actionType == ListActionType.bookmark
            ? '북마크 해제 ($selectedCount)'
            : '게시글 삭제 ($selectedCount)';
      }
    } else {
      // 일반 모드일 때
      return actionType == ListActionType.bookmark ? '북마크 해제' : '게시글 삭제';
    }
  }
}