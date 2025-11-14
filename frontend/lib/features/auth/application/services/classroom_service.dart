import 'package:socket_io_client/socket_io_client.dart' as IO;

class ClassroomService {
  late IO.Socket _socket;

  // Callbacks to notify the UI of various events
  final Function(String) onJoinedRoom;
  final Function(dynamic) onOfferReceived;
  final Function(dynamic) onAnswerReceived;
  final Function(dynamic) onIceCandidateReceived;

  ClassroomService({
    required this.onJoinedRoom,
    required this.onOfferReceived,
    required this.onAnswerReceived,
    required this.onIceCandidateReceived,
  });

  void connectAndJoin(String classId) {
    _socket = IO.io('http://10.0.2.2:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.onConnect((_) {
      print('Connected to signaling server');
      _socket.emit('join-room', classId);
    });

    _socket.onDisconnect((_) => print('Disconnected from signaling server'));

    // --- Register Event Listeners ---
    _socket.on('joined-room', (data) => onJoinedRoom(data));

    // Listen for WebRTC signaling events from other clients
    _socket.on('webrtc-offer', (data) => onOfferReceived(data));
    _socket.on('webrtc-answer', (data) => onAnswerReceived(data));
    _socket.on('webrtc-ice-candidate', (data) => onIceCandidateReceived(data));

    _socket.connect();
  }

  void dispose() {
    _socket.dispose();
  }
}
