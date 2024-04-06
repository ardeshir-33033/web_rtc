import 'dart:convert';

import 'package:webrtc_test/web_socket_connection.dart';


class AppGlobalData {
  static int userId = 194;
  static String? roomId;
}

class MessagingClient {
  final WebSocketConnection webSocketConnection;

  MessagingClient(this.webSocketConnection);

  void initState() {
    webSocketConnection.initState();
  }

  void resetState() {}

  // void connect({required String token}) {
  //   webSocketManager.connect(token: token);
  //   Timer.periodic(const Duration(seconds: 30), (timer) {
  //     sendPing();
  //   });
  // }

  sendSignal(String roomId) async {
    webSocketConnection.sendMessage("signaling", {
      'targetUserIds': [AppGlobalData.userId == 1 ? 194 : 1],
      'categoryId': 330,
      'signalingData': roomId,
    });
  }

  sendAddOnlineUser() async {
    webSocketConnection.sendMessage("addOnlineUser", {
      'userId': AppGlobalData.userId,
      'categoryId': 330,
    });
  }
}
