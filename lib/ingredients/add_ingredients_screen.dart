// Firestore에 재료를 추가하는 관리 화면
// 이 화면은 일회성으로 사용하여 재료 데이터를 Firestore에 추가하는 용도입니다.

import 'package:flutter/material.dart';
import 'add_ingredients_script.dart';
import '../common/app_colors.dart';

class AddIngredientsScreen extends StatefulWidget {
  const AddIngredientsScreen({super.key});

  @override
  State<AddIngredientsScreen> createState() => _AddIngredientsScreenState();
}

class _AddIngredientsScreenState extends State<AddIngredientsScreen> {
  final AddIngredientsScript _script = AddIngredientsScript();
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _addAllIngredients() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '재료 추가 중...';
    });

    try {
      await _script.addIngredients();
      setState(() {
        _statusMessage = '모든 재료 추가 완료!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '에러 발생: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addByCategory(String category) async {
    setState(() {
      _isLoading = true;
      _statusMessage = '$category 카테고리 재료 추가 중...';
    });

    try {
      await _script.addIngredientsByCategory(category);
      setState(() {
        _statusMessage = '$category 카테고리 재료 추가 완료!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '에러 발생: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _script.ingredientsByCategory.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('재료 추가 (관리자)'),
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
                  color: _statusMessage.contains('완료')
                      ? Colors.green.shade100
                      : _statusMessage.contains('에러')
                          ? Colors.red.shade100
                          : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('완료')
                        ? Colors.green.shade900
                        : _statusMessage.contains('에러')
                            ? Colors.red.shade900
                            : Colors.blue.shade900,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _addAllIngredients,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '모든 카테고리 재료 추가',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '카테고리별로 추가:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final count = _script.ingredientsByCategory[category]!.length;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(category),
                      subtitle: Text('$count개 재료'),
                      trailing: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _addByCategory(category),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

