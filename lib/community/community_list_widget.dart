import 'package:flutter/material.dart';

class CommunityListWidget extends StatelessWidget {
  const CommunityListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              '커뮤니티 화면',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '추후 구현 예정',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

