import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frontend/features/auth/application/services/classroom_service.dart';

class TeacherClassroomScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  const TeacherClassroomScreen({super.key, required this.classData});

  @override
  State<TeacherClassroomScreen> createState() => _TeacherClassroomScreenState();
}

class _TeacherClassroomScreenState extends State<TeacherClassroomScreen> {
  late ClassroomService _classroomService;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  bool _isBroadcasting = false;
  String _serverMessage = '';

  // WebRTC configuration
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
    await _localRenderer.initialize();
    _setupClassroomService();
  }

  void _setupClassroomService() {
    _classroomService = ClassroomService(
      onJoinedRoom: (message) {
        if (mounted) setState(() => _serverMessage = message);
      },
      onOfferReceived: (data) {
        // Teachers primarily send offers, but this could be useful for other scenarios
      },
      onAnswerReceived: (data) async {
        if (_peerConnection != null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(data['answer']['sdp'], data['answer']['type']),
          );
        }
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
    _localRenderer.dispose();
    _localStream?.getTracks().forEach((track) => track.stop());
    _peerConnection?.close();
    _classroomService.dispose();
    super.dispose();
  }

  Future<void> _toggleBroadcast() async {
    if (_isBroadcasting) {
      await _stopBroadcast();
      return;
    }
    await _startBroadcast();
  }

  Future<void> _startBroadcast() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'video': true,
        'audio': true,
      });
      _localRenderer.srcObject = _localStream;

      await _createPeerConnection();

      // Create and send an offer
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      _classroomService.sendOffer(widget.classData['class_id'], {'sdp': offer.sdp, 'type': offer.type});

      setState(() => _isBroadcasting = true);
    } catch (e) {
      print('Error starting broadcast: $e');
    }
  }

  Future<void> _stopBroadcast() async {
    try {
      _localStream?.getTracks().forEach((track) {
        track.stop();
      });
      await _peerConnection?.close();
      _peerConnection = null;
      _localRenderer.srcObject = null;
      setState(() => _isBroadcasting = false);
    } catch (e) {
      print('Error stopping broadcast: $e');
    }
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers, {});

    // Listen for ICE candidates and send them to the other peer
    _peerConnection!.onIceCandidate = (event) {
      if (event.candidate != null) {
        _classroomService.sendIceCandidate(widget.classData['class_id'], {
          'candidate': event.candidate!.candidate,
          'sdpMid': event.candidate!.sdpMid,
          'sdpMLineIndex': event.candidate!.sdpMLineIndex,
        });
      }
    };

    // Add local stream tracks to the peer connection
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });
  }

  @override
  Widget build(BuildContext context) {
    // UI remains largely the same
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classData['class_name']),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: _isBroadcasting
                  ? RTCVideoView(_localRenderer, mirror: true)
                  : const Center(
                      child: Text('البث متوقف', style: TextStyle(color: Colors.white)),
                    ),
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  _isBroadcasting ? Icons.videocam_off : Icons.videocam,
                  _isBroadcasting ? 'إيقاف البث' : 'بدء البث',
                  _toggleBroadcast,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(icon), onPressed: onPressed, iconSize: 30),
        Text(label),
      ],
    );
  }
}
