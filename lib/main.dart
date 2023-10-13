import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late String title;
  bool _loadPage = true;

  // GlobalKey可以获取到对应的Widget的State对象！
  // 当我们页面内容很多时，而需要改变的内容只有很少的一部分且在树的底层的时候，我们如何去实现增量更新？
  // 通常情况下有两种方式，第一种是通过方法的回调，去实现数据更新，第二种是通过GlobalKey
  final GlobalKey webViewKey = GlobalKey();

  // webView 配置
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    // 跨平台配置
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
    ),
    // android 平台配置
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true, // 使用混合集成
    ),
    // ios平台配置
    ios: IOSInAppWebViewOptions(
      allowsInlineMediaPlayback: true,
    )
  );

  late PullToRefreshController pullToRefreshController;
  late InAppWebViewController webViewController;
  double progress = 0;

  @override
  void initState() {
    super.initState();

    //flutter_inappwebview
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Stack(
          children: <Widget>[
            InAppWebView(
              key: webViewKey,
              // contextMenu: contextMenu,
              initialFile: 'assets/html/index.html',
              // initialUrlRequest: URLRequest(url: Uri.parse('https://baidu.com')), // h5的url,
              initialUserScripts: UnmodifiableListView<UserScript>([

              ]),
              initialOptions: options,
              // 刷新控制器
              pullToRefreshController: pullToRefreshController,
              /**
               * 与js交互传参
               * 添加在 InAppWebView 配置项里
               * InAppWebView 中获取 InAppWebViewController
               */
              onWebViewCreated: (InAppWebViewController controller) {
                webViewController = controller;
                // 注册一个JS处理方法，名称为myHandler
                controller.addJavaScriptHandler(
                    handlerName: 'myHandler',
                    callback: (args) {
                      // 打印js方传递过来的参数
                      print('args=js方传递过来的参数============================$args');
                      // 传给js方的参数(可以传递你所需要的任意类型数据，数组、对象等)
                      return "flutter给js的数据";
                    });
              },
              // 这个方法可以打印js中的console.log内容
              onConsoleMessage: (controller, consoleMessage) {
                print("consoleMessage==来自于js的打印====$consoleMessage");
              },
              onPageCommitVisible: (inAppWebViewController, uri) async {
                // _loadPage是声明的一个全局bool类型变量
                if (_loadPage) {
                  setState(() {
                    _loadPage = false;
                  });
                  // 获取到 webView 的所有 html 结构
                  var fileHtmlContents = await webViewController!.getHtml();
                  // 找到带有某种唯一标识的demo结构并替换它
                  fileHtmlContents = fileHtmlContents!.replaceAll(
                    '<div class="flutter-view"></div>',
                    "<div class='flutter-view' style='display: flex; justify-content: center; align-items: center; width: 200px; height: 200px; background-color: yellow;'>Hello Flutter</div>",
                  );
                  // 重新渲染结构
                  webViewController!.loadData(data: fileHtmlContents);
                }
              },
            ),
            progress < 1.0
                ? LinearProgressIndicator(value: progress, backgroundColor: Colors.blue,)
                : Container(),
          ],
        ),

      ),
    );
    /*return Container(
      child: InAppWebView(
        key: webViewKey,
        // initialUrlRequest: URLRequest(url: Uri.parse('https://wkinfo.com.cn')), // h5的url,
        initialFile: 'assets/html/index.html',
        initialOptions: options,
      ),
    );*/
  }
}
