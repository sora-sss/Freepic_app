import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PixabayPage(),
    );
  }
}

class PixabayPage extends StatefulWidget {
  const PixabayPage({super.key});

  @override
  State<PixabayPage> createState() => _PixabayPageState();
}

class _PixabayPageState extends State<PixabayPage> {
  // 初期値は空のListを与える
  List imageList = [];
  Future<void> fetchImages(String text) async {
    Response response = await Dio().get(
      'https://pixabay.com/api/?key=31242258-710e8c6ba7e46aebcb80eed71&q=$text&image_type=photo&pretty=true&per_page=100',
    );
    // 用意した imageList に hits の value を代入する
    imageList = response.data['hits'];
    setState(() {}); // 画面を更新したいので setState も呼んでおきます
  }

  // この関数の中の処理は初回に一度だけ実行されます。
  @override
  void initState() {
    super.initState();
    // 最初に一度だけ画像データを取得します。
    // 最初は花の画像を検索する。
    fetchImages('パン');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
          ),
          onFieldSubmitted: (text) {
            print(text);
            fetchImages(text);
          },
        ),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 横に並べる個数をここで決めます。今回は 3 にします。
        ),
        // itemCount には要素数を与えます。
        // List の要素数は .length で取得できます。今回は20になります。
        itemCount: imageList.length,
        // index には 0 ~ itemCount - 1 の数が順番に入ってきます。
        // 今回、要素数は 20 なので 0 ~ 19 が順番に入ります。
        itemBuilder: (context, index) {
          // 要素を順番に取り出します。
          // index には 0 ~ 19 の値が順番に入ること、
          // List から番号を指定して要素を取り出す書き方を思い出しながら眺めてください。
          Map<String, dynamic> image = imageList[index];
          // プレビュー用の画像データがあるURLは previewURL の value に入っています。
          // URLをつかった画像表示は Image.network(表示したいURL) で実装できます。
          return InkWell(
            onTap: () async {
              // まずは一時保存に使えるフォルダ情報を取得します。
              // Future 型なので await で待ちます
              Directory dir = await getTemporaryDirectory();
              Response response = await Dio().get(
                  // previewURL は荒いためより高解像度の webformatURL から画像をダウンロードします。
                  image['webformatURL'],
                  options: Options(responseType: ResponseType.bytes));
              File imageFile = await File('${dir.path}/image.png')
                  .writeAsBytes(response.data);
              // path を指定すると share できます。
              await Share.shareFiles([imageFile.path]);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  image['previewURL'],
                  fit: BoxFit.cover,
                ),
                // いいね数は likes key の value に入っています。
                // 型は int なので .toString() を実行すると文字列に変換できます。
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                      color: Colors.white.withOpacity(0.9),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 14,
                          ),
                          Text(image['likes'].toString()),
                        ],
                      )),
                ),
                // 別解：コードを文字列として評価したい場合は '${評価したいコード}' とも書けます。
                // Text('${image['likes']}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
