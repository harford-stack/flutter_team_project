import 'package:flutter/material.dart';

class CommunityListScreen extends StatefulWidget {
  const CommunityListScreen({super.key});

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {

  ///변수 선언 구역
  final TextEditingController _searchcontroller = TextEditingController();
  //dropdown
  String _sortOrder='시간순';//设置初始化的值

  ///widget 선언 구역
  //검색
  Widget _buildSearch(){
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      child: Column(
        children: [
          // 第一行：搜索框 + 搜索按钮
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchcontroller,
                  decoration: const InputDecoration(
                    hintText: '게시글 제목이나 내용으로 검색',
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: (){
                  //검색 함수
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text("검색"),
              ),
            ],
          ),

          SizedBox(height: 12),

          //두번째 행의 dropdown
          // 第二行：右侧对齐的 Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 100, // 固定宽度
                child: DropdownButtonFormField<String>(
                  value: _sortOrder,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: '시간순', child: Text('시간순', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: '조회순', child: Text('조회순', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: '인기순', child: Text('인기순', style: TextStyle(fontSize: 14))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortOrder = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // //게시글 목록
  // Widget _buildPostList(){
  //   return Padding(
  //     padding: const EdgeInsets.all(12),
  //     child: GridView.builder(
  //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //         crossAxisCount: 2,
  //         crossAxisSpacing: 8,
  //         mainAxisSpacing: 8,
  //       ),
  //       // itemBuilder:,
  //       // itemCount:,
  //     ),
  //   );
  // }


  //dispose
  @override
  void dispose(){
    _searchcontroller.dispose();
    super.dispose();
  }

  ///화면 구역
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      //1. 앱바
        appBar:AppBar(
          //통일 appBar

        ),

        //2. 바디
        body: Container(
          child:Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              //2.1 검색란
              _buildSearch(),
              // _buildPostList(),
            ],
          )
        ),

        //밑에 있는 네이버 바
        bottomNavigationBar: BottomAppBar(
          //통일 bottomnaverbar
        ),
      );


  }
}
