import 'package:socket_io_client/socket_io_client.dart' as IO;

class ClassroomService {
  late IO.Socket _socket;

  // Callbacks to notify the UI of various events
  final Function(String) onJoinedRoom;
  final Function(dynamic) onOfferReceived;
  final Function(dynamic) onAnswerReceived;
  final Function(dynamic) onIceCandidateReceived;
  final Function(dynamic) onChatMessageReceived;
  final Function(dynamic) onRequestToSpeakReceived; // New callback

  ClassroomService({
    required this.onJoinedRoom,
    required this.onOfferReceived,
    required this.onAnswerReceived,
    required this.onIceCandidateReceived,
    required this.onChatMessageReceived,
    required this.onRequestToSpeakReceived, // New callback
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
    _socket.on('chat-message', (data) => onChatMessageReceived(data));
    _socket.on('request-to-speak', (data) => onRequestToSpeakReceived(data)); // Listen for requests

    // Listen for WebRTC signaling events

    // Listen for WebRTC signaling events from other clients
    _socket.on('webrtc-offer', (data) => onOfferReceived(data));
    _socket.on('webrtc-answer', (data) => onAnswerReceived(data));
    _socket.on('webrtc-ice-candidate', (data) => onIceCandidateReceived(data));

    _socket.connect();
  }

  // --- Emitter Functions ---

  void sendChatMessage(String classId, String message) {
    _socket.emit('chat-message', {'classId': classId, 'message': message});
  }
  // --- Emitter Functions to send data to the server ---

  void sendOffer(String classId, dynamic offer) {
    _socket.emit('webrtc-offer', {'classId': classId, 'offer': offer});
  }

  void sendAnswer(String classId, dynamic answer) {
    _socket.emit('webrtc-answer', {'classId': classId, 'answer': answer});
  }

  void sendIceCandidate(String classId, dynamic candidate) {
    _socket.emit('webrtc-ice-candidate', {'classId': classId, 'candidate': candidate});
  }

  void sendRequestToSpeak(String classId, String studentId, String studentName) {
    _socket.emit('request-to-speak', {
      'classId': classId,
      'studentId': studentId,
      'studentName': studentName,
    });
  }

  void dispose() {
    _socket.dispose();
  }
}
