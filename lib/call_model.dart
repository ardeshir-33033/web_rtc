import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallModel {
  TextEditingController textController = TextEditingController();
  RTCVideoRenderer? remoteRenderer;
  RTCPeerConnection? peerConnection;
}
