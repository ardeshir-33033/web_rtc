import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:webrtc_test/signaling.dart';

import 'messaging_client.dart';
import 'web_socket_connection.dart';

final locator = GetIt.instance;

void injectDependencies() {
  locator
      .registerLazySingleton<WebSocketConnection>(() => WebSocketConnection());
  locator
      .registerLazySingleton<MessagingClient>(() => MessagingClient(locator()));
  locator.registerSingleton<Signaling>(Get.put(Signaling()));
}
