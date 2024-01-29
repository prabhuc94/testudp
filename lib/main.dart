import 'dart:async';
import 'dart:convert';
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
  int _counter = 0;
  String broadcastMessage = "";

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  RawDatagramSocket? udpSocket;
  List<String> _messages = [];
  StreamController<List<String>> socketMessages = StreamController.broadcast(
      sync: true);

  sendUDPMessages() async {
    print("SENDING-MESSAGE");
    var DESTINATION_ADDRESS = InternetAddress("192.168.29.105");
    udpSocket?.send(utf8.encode("Testing ${DateTime.now().toIso8601String()}"),
        DESTINATION_ADDRESS, 4444);
    print("SENT-MESSAGE");
    /*var DESTINATION_ADDRESS = InternetAddress("192.168.29.105");
    RawDatagramSocket.bind(InternetAddress.anyIPv4, 4444).then((RawDatagramSocket udpSocket) {
      print('SOCKET-CONNECTED');
      udpSocket.broadcastEnabled = true;
      udpSocket.listen((e) {
        Datagram? dg = udpSocket.receive();
        if (dg != null) {
          print("RECEIVED DATA AS ${String.fromCharCodes(dg.data).toString()}");
          setState(() {
            broadcastMessage = "received the Data as : ${dg.data}";
          });
        }
      });
      List<int> data = utf8.encode('TEST Message from Prabhu system ${DateTime.now().toIso8601String()}');
      udpSocket.send(data, DESTINATION_ADDRESS, 4444);
    }).catchError((e) {
      print("SEND-MESSAGE-CATCH ${e}");
    });*/
  }

  @override
  void initState() {
    _initializeReceiver();
    super.initState();
  }

  void _initializeReceiver() async {
    var socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4444);
    socket.listen((event) {
      var data = socket.receive();
      if (data != null) {
        String value = String.fromCharCodes(data.data).trim();
        _messages.add("${data.address..address}:${data.port} - $value");
      }
    });
  }

  void sendData() async {
    // Create a UDP socket
    RawDatagramSocket socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4, 0);

    // Encode the message to bytes
    List<int> data = utf8.encode("Hello, UDP! ${DateTime.now().toIso8601String()}");

    // Send the data to the specified address and port
    socket.send(data, InternetAddress.loopbackIPv4, 4444);

    // Close the socket
    socket.close();
  }

  void _initialize() async {
    udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4444);
    if (udpSocket != null) {
      udpSocket?.broadcastEnabled = true;
      print("SOCKET-CONNECTED ${udpSocket?.broadcastEnabled}");
      udpSocket?.listen((event) {
        var data = udpSocket?.receive();
        print("LISTEN $event");
        if (event == RawSocketEvent.read) {
          if (data != null) {
            var value = String.fromCharCodes(data.data);
            print("SOCKET-LISTEN ${value}");
          }
        }
      });
    }
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
        stream: socketMessages.stream,
        builder: (context, snapshot) {
          var data = snapshot.data;
          return ListView.separated(itemBuilder: (context, index) {
            var model = data?[index];
            return Flexible(child: Text("$model"));
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
