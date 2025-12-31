//재료 입력 화면

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../common/app_colors.dart';
import '../common/custom_appbar.dart';
import '../common/custom_drawer.dart';

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
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      drawer: CustomDrawer(),
      appBar: CustomAppBar(
        appName: '재료 등록',
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: screenSize.width * 0.6,   // 화면 가로의 60%
              height: screenSize.height * 0.12, // 화면 세로의 12%
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.textWhite,
                  elevation: 0,
                  // minimumSize: const Size(20, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  _pickFromCamera();
                },
                child: Text(
                  "사진 촬영",
                  style: TextStyle(
                    fontSize: screenSize.width * 0.05
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: screenSize.width * 0.6,   // 화면 가로의 60%
              height: screenSize.height * 0.12, // 화면 세로의 12%
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.textWhite,
                  elevation: 0,
                  // minimumSize: const Size(20, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  _pickFromGallery();
                },
                child: Text(
                  "이미지 선택",
                  style: TextStyle(
                      fontSize: screenSize.width * 0.05
                  ),
                ),
              ),
            ),
            // ElevatedButton(
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: AppColors.primaryColor,
            //     foregroundColor: AppColors.textWhite,
            //     elevation: 0,
            //     minimumSize: const Size(200, 50),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(6),
            //     ),
            //   ),
            //   onPressed: () {
            //     showDialog(
            //       context: context,
            //       barrierDismissible: true,
            //       builder: (context) {
            //         return Dialog(
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(12),
            //           ),
            //           child: Padding(
            //             padding: const EdgeInsets.all(16),
            //             child: Column(
            //               mainAxisSize: MainAxisSize.min,
            //               children: [
            //                 SizedBox(
            //                   width: 150,
            //                   child: ElevatedButton(
            //                     style: ElevatedButton.styleFrom(
            //                       backgroundColor: AppColors.primaryColor,
            //                       foregroundColor: AppColors.textWhite,
            //                       elevation: 0,
            //                       // minimumSize: const Size(20, 48),
            //                       shape: RoundedRectangleBorder(
            //                         borderRadius: BorderRadius.circular(6),
            //                       ),
            //                     ),
            //                     onPressed: () {
            //                       _pickFromCamera();
            //                     },
            //                     child: const Text("사진 촬영"),
            //                   ),
            //                 ),
            //                 const SizedBox(height: 12),
            //                 SizedBox(
            //                   width: 150,
            //                   child: ElevatedButton(
            //                     style: ElevatedButton.styleFrom(
            //                       backgroundColor: AppColors.primaryColor,
            //                       foregroundColor: AppColors.textWhite,
            //                       elevation: 0,
            //                       // minimumSize: const Size(20, 48),
            //                       shape: RoundedRectangleBorder(
            //                         borderRadius: BorderRadius.circular(6),
            //                       ),
            //                     ),
            //                     onPressed: () {
            //                       _pickFromGallery();
            //                     },
            //                     child: const Text("이미지 선택"),
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //         );
            //       },
            //     );
            //   },
            //   child: const Text("사진 등록"),
            // ),
            // const SizedBox(height: 20),
            // ElevatedButton(
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: AppColors.primaryColor,
            //     foregroundColor: AppColors.textWhite,
            //     elevation: 0,
            //     minimumSize: const Size(200, 50),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(6),
            //     ),
            //   ),
            //   onPressed: () {
            //     Navigator.push(
            //         context,
            //         MaterialPageRoute(builder: (_)=>SelectScreen())
            //     );
            //   },
            //   child: const Text("목록에서 선택"),
            // ),
          ],
        ),
      ),
    );
  }
}