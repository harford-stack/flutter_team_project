import 'package:flutter/material.dart';

void main() {
  runApp(const regist());
}

class regist extends StatelessWidget {
  const regist({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300, // 버튼 배경색
                    foregroundColor: Colors.black,         // 글자색
                    elevation: 0,                          // 그림자
                    minimumSize: const Size(200, 50),      // 버튼 크기
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6), // 둥글기
                    ),
                  ),
                  onPressed: (){
                    
                  }, 
                  child: Text("사진 등록")
              ),
              SizedBox(height: 20,),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300, // 버튼 배경색
                    foregroundColor: Colors.black,         // 글자색
                    elevation: 0,                          // 그림자
                    minimumSize: const Size(200, 50),      // 버튼 크기
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6), // 둥글기
                    ),
                  ),
                  onPressed: (){

                  },
                  child: Text("목록에서 선택")
              )
            ],
          ),
        )
      ),
    );
  }
}
