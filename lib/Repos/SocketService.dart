import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _singleton = SocketService._internal();

  factory SocketService() {
    return _singleton;
  }

  SocketService._internal() {
    socket = IO.io('http://16.162.14.221:4000/', <String, dynamic>{
      'transports': ['websocket'],
    });
  }

  late IO.Socket socket;

  void connect() {
    socket.connect();
  }

  void disconnect() {
    socket.disconnect();
  }
}
