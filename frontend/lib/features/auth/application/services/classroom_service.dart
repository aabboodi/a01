import 'package:socket_io_client/socket_io_client.dart' as IO;

class ClassroomService {
  late IO.Socket socket;

  // Callbacks to notify the UI of various events
  final Function(String) onJoinedRoom;
  final Function(dynamic) onOfferReceived;
  final Function(dynamic) onAnswerReceived;
  final Function(dynamic) onIceCandidateReceived;
  final Function(dynamic) onChatMessageReceived;
  final Function(dynamic) onRequestToSpeakReceived;
  final Function(dynamic) onPermissionToSpeakReceived; // For student
  final Function(dynamic) onUserJoined;
  final Function(dynamic) onUserLeft;
  final Function(dynamic) onCurrentAttendanceReceived;

  ClassroomService({
    required this.onJoinedRoom,
    required this.onOfferReceived,
    required this.onAnswerReceived,
    required this.onIceCandidateReceived,
    required this.onChatMessageReceived,
    required this.onRequestToSpeakReceived,
    required this.onPermissionToSpeakReceived,
    required this.onUserJoined,
    required this.onUserLeft,
    required this.onCurrentAttendanceReceived,
  });

  void connectAndJoin(String classId, String userId, String fullName) {
    socket = IO.io('http://10.0.2.2:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.onConnect((_) {
      print('Connected to signaling server');
      socket.emit('join-room', {
        'classId': classId,
        'userId': userId,
        'fullName': fullName,
      });
    });

    socket.onDisconnect((_) => print('Disconnected from signaling server'));

    // --- Register Event Listeners ---
    socket.on('joined-room', (data) => onJoinedRoom(data));
    socket.on('chat-message', (data) => onChatMessageReceived(data));
    socket.on('request-to-speak', (data) => onRequestToSpeakReceived(data)); // Listen for requests

    // Listen for WebRTC signaling events

    // Listen for WebRTC signaling events from other clients
    socket.on('webrtc-offer', (data) => onOfferReceived(data));
    socket.on('webrtc-answer', (data) => onAnswerReceived(data));
    socket.on('webrtc-ice-candidate', (data) => onIceCandidateReceived(data));
    socket.on('permission-to-speak', (data) => onPermissionToSpeakReceived(data));
    socket.on('user-joined', (data) => onUserJoined(data));
    socket.on('user-left', (data) => onUserLeft(data));
    socket.on('current-attendance', (data) => onCurrentAttendanceReceived(data));

    socket.connect();
  }

  // --- Emitter Functions ---

  void sendChatMessage(String classId, String message, {required String userId}) {
    socket.emit('chat-message', {'classId': classId, 'message': message, 'userId': userId});
  }

  void sendOffer(String classId, dynamic offer, {String? targetId}) {
    socket.emit('webrtc-offer', {'classId': classId, 'offer': offer, 'targetId': targetId});
  }

  void sendAnswer(String classId, dynamic answer, {required String targetId}) {
    socket.emit('webrtc-answer', {'classId': classId, 'answer': answer, 'targetId': targetId});
  }

  void sendIceCandidate(String classId, dynamic candidate, {String? targetId}) {
    socket.emit('webrtc-ice-candidate', {'classId': classId, 'candidate': candidate, 'targetId': targetId});
  }

  void sendRequestToSpeak(String classId, String studentId, String studentName) {
    socket.emit('request-to-speak', {
      'classId': classId,
      'studentId': studentId,
      'studentName': studentName,
    });
  }

  void allowToSpeak(String studentSocketId) {
    socket.emit('allow-to-speak', {'studentSocketId': studentSocketId});
  }

  void dispose() {
    socket.dispose();
  }
}
