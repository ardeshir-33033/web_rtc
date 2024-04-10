import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:webrtc_test/signaling.dart';

import 'firebase_options.dart';
import 'locator.dart';
import 'messaging_client.dart';

Future<bool> startForegroundService() async {
  final androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: 'Title of the notification',
    notificationText: 'Text of the notification',
    notificationImportance: AndroidNotificationImportance.Default,
    notificationIcon: AndroidResource(
        name: 'background_icon',
        defType: 'drawable'), // Default is ic_launcher from folder mipmap
  );
  await FlutterBackground.initialize(androidConfig: androidConfig);
  await Future.delayed(Duration(seconds: 1), () {
    FlutterBackground.enableBackgroundExecution();
  });
  return true;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  injectDependencies();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (WebRTC.platformIsAndroid) {
    startForegroundService();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Signaling signaling = locator<Signaling>();
  Signaling signaling2 = Signaling();

  String? roomId;
  TextEditingController textEditingController = TextEditingController(text: '');

  String? roomId2;
  TextEditingController textEditingController2 =
      TextEditingController(text: '');

  @override
  void initState() {
    signaling.localRenderer.initialize();
    signaling.remoteRenderer.initialize();

    signaling.onAddRemoteStream = ((stream) {
      signaling.remoteRenderer.srcObject = stream;
      setState(() {});
    });

    signaling2.localRenderer.initialize();
    signaling2.remoteRenderer.initialize();
    signaling2.onAddRemoteStream = ((stream) {
      signaling2.remoteRenderer.srcObject = stream;
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    signaling.localRenderer.dispose();
    signaling.remoteRenderer.dispose();

    signaling2.localRenderer.dispose();
    signaling2.remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GetBuilder<Signaling>(
            id: "ui",
            builder: (logic) {
              return Column(
                children: [
                  SizedBox(height: 8),
                  SizedBox(
                    height: 30,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            signaling.openUserMedia();
                          },
                          child: Text("Cam & Mic"),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            roomId = await signaling.createRoom();
                            textEditingController.text = roomId!;
                            setState(() {});
                          },
                          child: Text("Create room"),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Add roomId
                            signaling.joinRoom(
                              textEditingController.text.trim(),
                            );
                          },
                          child: Text("Join room"),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            signaling.hangUp();
                          },
                          child: Text("Hangup"),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 30,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            signaling2.openUserMedia();
                          },
                          child: Text("Cam & Mic 2"),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            roomId2 = await signaling2.createRoom();
                            textEditingController2.text = roomId2!;
                            setState(() {});
                          },
                          child: Text("Create room 2 "),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Add roomId
                            signaling2.joinRoom(
                              textEditingController2.text.trim(),
                            );
                          },
                          child: Text("Join room 2"),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            signaling2.hangUp();
                          },
                          child: Text("Hangup 2 "),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                              child: RTCVideoView(signaling.localRenderer,
                                  mirror: true)),
                          Expanded(
                              child: RTCVideoView(signaling.remoteRenderer)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                              child: RTCVideoView(signaling2.localRenderer,
                                  mirror: true)),
                          Expanded(
                              child: RTCVideoView(signaling2.remoteRenderer)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      IconButton(
                          color:
                              signaling.enableAudio ? Colors.green : Colors.red,
                          onPressed: () {
                            signaling.toggleAudio();
                            setState(() {});
                          },
                          icon: Icon(Icons.keyboard_voice, size: 30)),
                      SizedBox(width: 20),
                      IconButton(
                          color:
                              signaling.enableVideo ? Colors.green : Colors.red,
                          onPressed: () {
                            signaling.toggleVideo();
                            setState(() {});
                          },
                          icon: Icon(Icons.video_call, size: 30)),
                      SizedBox(width: 20),
                      IconButton(
                          color: signaling.isFrontCameraSelected
                              ? Colors.green
                              : Colors.red,
                          onPressed: () {
                            signaling.switchCamera();
                            // setState(() {});
                          },
                          icon: Icon(Icons.cameraswitch, size: 30)),
                      SizedBox(width: 20),
                      IconButton(
                          color: signaling.speakerPhone
                              ? Colors.green
                              : Colors.red,
                          onPressed: () {
                            signaling.toggleSpeaker();
                            // setState(() {});
                          },
                          icon: Icon(
                            Icons.speaker,
                            size: 30,
                          )),
                      SizedBox(width: 20),
                      IconButton(
                          color:
                              signaling.enableTorch ? Colors.green : Colors.red,
                          onPressed: () {
                            if (!signaling.isFrontCameraSelected)
                              signaling.toggleTorch();
                          },
                          icon: Icon(
                            Icons.flash_on,
                            size: 30,
                          )),
                      SizedBox(width: 20),
                      IconButton(
                          color: Colors.green,
                          onPressed: () {
                            signaling.captureFrame();
                          },
                          icon: Icon(
                            Icons.camera,
                            size: 30,
                          )),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      IconButton(
                          color: signaling.isScreenShared
                              ? Colors.green
                              : Colors.red,
                          onPressed: () {
                            if (signaling.isScreenShared) {
                              signaling.disableShareScreen();
                            } else {
                              signaling.makeScreenSharing();
                            }
                          },
                          icon: Icon(
                            Icons.ios_share_sharp,
                            size: 30,
                          )),
                    ],
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Room: "),
                        Flexible(
                          child: TextFormField(
                            controller: textEditingController,
                          ),
                        ),
                        ElevatedButton(
                            onPressed: () {
                              if (AppGlobalData.roomId != null) {
                                textEditingController.text =
                                    AppGlobalData.roomId!;
                              }
                            },
                            child: Container(
                              height: 20,
                              width: 50,
                              child: Text("Get RoomId"),
                            )),
                        ElevatedButton(
                            onPressed: () {
                              locator<MessagingClient>().initState();
                            },
                            child: Container(
                              height: 20,
                              width: 50,
                              child: Text("Connect"),
                            )),
                        Text(AppGlobalData.userId.toString()),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Room2: "),
                        Flexible(
                          child: TextFormField(
                            controller: textEditingController2,
                          ),
                        ),
                        ElevatedButton(
                            onPressed: () {
                              if (AppGlobalData.roomId != null) {
                                textEditingController2.text =
                                AppGlobalData.roomId!;
                              }
                            },
                            child: Container(
                              height: 20,
                              width: 50,
                              child: Text("Get RoomId"),
                            )),
                        ElevatedButton(
                            onPressed: () {
                              locator<MessagingClient>().initState();
                            },
                            child: Container(
                              height: 20,
                              width: 50,
                              child: Text("Connect"),
                            )),
                        Text(AppGlobalData.userId.toString()),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),

                ],
              );
            }),
      ),
    );
  }
}
