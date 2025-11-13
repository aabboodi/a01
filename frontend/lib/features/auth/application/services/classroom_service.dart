import 'package:socket_io_client/socket_io_client.dart' as IO;

class ClassroomService {
  late IO.Socket _socket;

  // Callback to notify the UI when a message is received
  final Function(String) onJoinedRoom;

  ClassroomService({required this.onJoinedRoom});

  void connectAndJoin(String classId) {
    // NOTE: Use the actual IP of your machine when testing on a real device,
    // not localhost. 10.0.2.2 is for the Android emulator.
    _socket = IO.io('http://10.0.2.2:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    // Handle connection events
    _socket.onConnect((_) {
      print('Connected to signaling server');
      // Once connected, join the specific class room
      _socket.emit('join-room', classId);
    });

    _socket.onDisconnect((_) => print('Disconnected from signaling server'));
    _socket.onConnectError((data) => print('Connection Error: $data'));
    _socket.onError((data) => print('Error: $data'));

    // Listen for custom events from the server
    _socket.on('joined-room', (data) {
      print('Server acknowledged room join: $data');
      onJoinedRoom(data); // Notify the UI
    });

    // Finally, connect
    _socket.connect();
  }

  void dispose() {
    _socket.dispose();
  }
}
