import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';

import 'locator.dart';
import 'messaging_client.dart';

class WebSocketConnection {
  IO.Socket? channel;
  bool isConnected = false;

  void initState() {
    initChannel();
  }

  void resetState() async {
    channel = null;
    isConnected = false;
    // notifyListeners();
  }

  Future initChannel() async {
    // Map<String , dynamic>  headers = HttpHeader.setHeaders(HttpHeaderType.webSocket);

    channel = IO.io("https://socket.raeis.de",
        IO.OptionBuilder().setTransports(["websocket"]).build());
    channel?.onConnect((data) {
      isConnected = true;
      print("Socket Id: ${channel!.id}");
      locator<MessagingClient>().sendAddOnlineUser();

      print(
          "-----------------   Successful Connection   $data  -----------------");
    });

    channel?.onConnectError((data) {
      print("-----------------   Connection Error $data     -----------------");
    });

    channel?.onDisconnect((data) {
      isConnected = false;
      print("-----------------   Disconnected     -----------------");
    });

    channel?.onAny((event, data) {
      print("$event : data");
    });

    channel?.on("signaling", (data) {
      print(data);
      AppGlobalData.roomId = data;
      // locator<CallController>().receiveCallSignal(data);
    });
  }

  void sendMessage(String event, dynamic payload) {
    print("----------   $event : $payload --------");
    if (isConnected) {
      channel?.emit(event, payload);
    }
  }

  void closeConnection() {
    channel?.close();
    channel = null;
    isConnected = false;
  }

  Future retryConnection() async {
    if (isConnected) return;
    await initChannel();
  }
}
