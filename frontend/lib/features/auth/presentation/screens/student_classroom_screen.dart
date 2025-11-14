import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frontend/features/auth/application/services/classroom_service.dart';

class StudentClassroomScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  final Map<String, dynamic> userData; // Added userData

  const StudentClassroomScreen({
    super.key,
    required this.classData,
    required this.userData, // Added userData
  });

  @override
  State<StudentClassroomScreen> createState() => _StudentClassroomScreenState();
}

class _StudentClassroomScreenState extends State<StudentClassroomScreen> {
  late ClassroomService _classroomService;
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  String _serverMessage = '';
  bool _requestSent = false;

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ]
  };

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _remoteRenderer.initialize();
    _setupClassroomService();
  }

  void _setupClassroomService() {
    // ... (service setup remains the same)
        _classroomService = ClassroomService(
      onJoinedRoom: (message) {
        if (mounted) setState(() => _serverMessage = message);
      },
      onOfferReceived: (data) async {
        print("Offer received");
        await _createPeerConnection();
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(data['offer']['sdp'], data['offer']['type']),
        );
        RTCSessionDescription answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        _classroomService.sendAnswer(widget.classData['class_id'], {'sdp': answer.sdp, 'type': answer.type});
      },
      onAnswerReceived: (data) {
        // Students primarily receive offers, so this is less likely to be used.
      },
      onIceCandidateReceived: (data) async {
        if (_peerConnection != null) {
          await _peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate']['candidate'],
              data['candidate']['sdpMid'],
              data['candidate']['sdpMLineIndex'],
            ),
          );
        }
      },
    );
    _classroomService.connectAndJoin(widget.classData['class_id']);
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _peerConnection?.close();
    _classroomService.dispose();
    super.dispose();
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers, {});

    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video') {
        _remoteRenderer.srcObject = event.streams[0];
      }
    };
  }

  void _handleRequestToSpeak() {
    _classroomService.sendRequestToSpeak(
      widget.classData['class_id'],
      widget.userData['user_id'],
      widget.userData['full_name'],
    );
    setState(() => _requestSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال طلب المداخلة بنجاح.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classData['class_name']),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: RTCVideoView(_remoteRenderer, mirror: true),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.blueGrey[100],
            child: Text('حالة الخادم: $_serverMessage'),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.pan_tool,
                        color: _requestSent ? Colors.grey : Colors.blue,
                      ),
                      onPressed: _requestSent ? null : _handleRequestToSpeak,
                      iconSize: 30,
                    ),
                    const Text('طلب مداخلة'),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
