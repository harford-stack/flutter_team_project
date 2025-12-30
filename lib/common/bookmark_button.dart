// 북마크 공통 버튼 (모양과 UI 동작)
// '나의 레시피(히스토리)', 커뮤니티 북마크의 디자인 통일성과 유지보수 위함
// 각 담당 화면에서 import해서 쓰면 됨

import 'package:flutter/material.dart';

class BookmarkButton extends StatefulWidget {
  final bool isInitialBookmarked; // ★ 추가: 시작 시 북마크 여부
  final Function(bool) onToggle;
  final double size;         // 아이콘 크기 조절
  final bool isTransparent;  // 배경색 유무 (상세페이지용)

  const BookmarkButton({
    super.key,
    this.isInitialBookmarked = false, // 기본값은 false
    required this.onToggle,
    this.size = 24,
    this.isTransparent = false, // 기본은 회색 리스트용 배경 있음
  });

  @override
  State<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<BookmarkButton> {
  late bool isBookmarked = false; // // 초기화를 위해 late 선언

  @override
  void initState() {
    super.initState();
    // 부모로부터 받은 초기값을 상태변수에 할당
    isBookmarked = widget.isInitialBookmarked;
  }

  void _handleTap() {
    setState(() {
      isBookmarked = !isBookmarked;
    });

    widget.onToggle(isBookmarked);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isBookmarked ? '북마크에 추가되었습니다.' : '북마크가 해제되었습니다.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        decoration: BoxDecoration(
          // isTransparent가 true면 배경을 투명하게 처리
          color: widget.isTransparent ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.all(widget.isTransparent ? 0 : 4), // 배경 없으면 패딩도 0
        child: Icon(
          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          color: isBookmarked ? Colors.blue : Colors.black,
          size: widget.size,
        ),
      ),
    );
  }
}