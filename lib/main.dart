import 'dart:async';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io';

import 'package:flutter/material.dart';

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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String broadcastMessage = "";
  final int port = 19302;
  final stunServerDomain = 'stun.l.google.com';
  late InternetAddress address;

  RawDatagramSocket? socket;
  List<String> _messages = [];
  StreamController<List<String>> socketMessages = StreamController.broadcast(
      sync: true);

  @override
  void initState() {
    _initializeReceiver();
    super.initState();
  }

  void _initializeServerSocket() async {
    var uri = Uri.parse("wss://0.peerjs.com:443/peerjs?key=peerjs&id=prabhu@yopmail.com&token=ssdsew&version=1");
    final channel = WebSocketChannel.connect(uri);
    await channel.ready;

    channel.stream.listen((event) {
      print("EVENT [${TimeOfDay.now().format(context)}]: ${event}");
    }, onDone: () {
      print("ONDONE [${TimeOfDay.now().format(context)}]: SOCKET-CLOSED");
    }, onError: (val) {
      print("ONERROR [${TimeOfDay.now().format(context)}]: SOCKET-ERROR: $val");
    });
  }

  void _initializeReceiver() async {
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    var addre = (await InternetAddress.lookup(stunServerDomain)).lastOrNull;
    address = InternetAddress("${addre?.address}");
    print('ADDRESSS: ${addre?.address}');
    socket?.send("Sever Connected".codeUnits, InternetAddress.loopbackIPv4, port);
    // socket?.joinMulticast(address);
    socket?.send("Multicast group joined".codeUnits, InternetAddress.loopbackIPv4, port);
    socket?.listen((event) {
      var data = socket?.receive();
      if (data != null) {
        String value = String.fromCharCodes(data.data).trim();
        _messages.add("${data.address.address}:${data.port} - $value");
        socketMessages.sink.add(_messages);
      }
    });
  }
  
  Future<bool> portExist(int portNumber) async {
    try {
      var value = await ServerSocket.bind(InternetAddress.anyIPv4, portNumber);
      return true;
    } catch(e) {
      return false;
    }
  }

  void sendData() async {
    RawDatagramSocket soc = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    soc.send("Hello [${Platform.operatingSystem}], UDP! ${DateTime.now().toIso8601String()}".codeUnits, address, port);
    soc.listen((event) {
      print("EVENT ${event.runtimeType}");
    }, onError: (e) {
      print("SENDING-ERROR ${e}");
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: StreamBuilder(
        initialData: _messages,
        stream: socketMessages.stream,
        builder: (context, snapshot) {
          var data = snapshot.data;
          return ListView.separated(itemBuilder: (context, index) {
            var model = data?[index];
            return Text("$model");
          },
              separatorBuilder: (context, index) => Divider(),
              itemCount: data?.length ?? 0);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: sendData,
        tooltip: 'Send',
        child: const Icon(Icons.send),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
