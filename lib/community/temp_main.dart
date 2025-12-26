import 'package:flutter/material.dart';
import 'package:flutter_team_project/community/community_list_screen.dart';

void main() {
  runApp(const TempMain());
}

class TempMain extends StatelessWidget {
  const TempMain({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CommunityListScreen(),
                  ),
                );
              },
              child: const Text('커뮤니티 이동'),
            ),
          ],
        ),
      ),
    );
  }
}