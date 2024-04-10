import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallModel {
  TextEditingController textController;
  RTCVideoRenderer? remoteRenderer;
  RTCPeerConnection? peerConnection;
  String? roomId;

  CallModel(
      {this.peerConnection,
      this.roomId,
      required this.textController,
      this.remoteRenderer});
}
