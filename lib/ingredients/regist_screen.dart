//재료 입력 화면

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../common/app_colors.dart';
import '../common/custom_appbar.dart';

import 'select_screen.dart';
import 'image_confirm.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MaterialApp(
    home: Regist(),  // 또는 IngredientRegistScreen()
  ));
}

class IngredientRegistScreen extends StatelessWidget {
  const IngredientRegistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              '재료 등록 화면',
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

class Regist extends StatefulWidget {
  const Regist({super.key});

  @override
  State<Regist> createState() => _RegistState();
}

class _RegistState extends State<Regist> {
  final ImagePicker _picker = ImagePicker();
  File? _image;

  Future<void> _pickFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if(pickedFile != null){
      _image = File(pickedFile.path);
      setState(() {
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ImageConfirm(imageFile:_image!),
            )
        );
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);


    if(pickedFile != null){
      _image = File(pickedFile.path);
      setState(() {
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ImageConfirm(imageFile:_image!),
            )
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        appName: '재료 등록',
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.textWhite,
                elevation: 0,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) {
                    return Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 150,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  foregroundColor: AppColors.textWhite,
                                  elevation: 0,
                                  // minimumSize: const Size(20, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: () {
                                  _pickFromCamera();
                                },
                                child: const Text("사진 촬영"),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: 150,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  foregroundColor: AppColors.textWhite,
                                  elevation: 0,
                                  // minimumSize: const Size(20, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: () {
                                  _pickFromGallery();
                                },
                                child: const Text("이미지 선택"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: const Text("사진 등록"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.textWhite,
                elevation: 0,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_)=>SelectScreen())
                );
              },
              child: const Text("목록에서 선택"),
            ),
          ],
        ),
      ),
    );
  }
}