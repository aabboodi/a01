import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frontend/features/auth/application/services/classroom_service.dart';

// ... (ChatMessage and SpeakRequest classes remain the same)
class ChatMessage {
  final String message;
  final String senderId;
  final bool isLocal;

  ChatMessage({required this.message, required this.senderId, required this.isLocal});
}

class SpeakRequest {
  final String studentId;
  final String studentName;
  final String socketId;

  SpeakRequest({required this.studentId, required this.studentName, required this.socketId});
}


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
  bool _isScreenSharing = false; // New state for screen sharing
  String _serverMessage = '';

  // ... (Chat and Speak Requests state remain the same)
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<SpeakRequest> _speakRequests = [];

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
    // ... (Service setup remains the same)
        _classroomService = ClassroomService(
      onJoinedRoom: (message) {
        if (mounted) setState(() => _serverMessage = message);
      },
      onChatMessageReceived: (data) {
        if (mounted) {
          setState(() {
            _chatMessages.add(ChatMessage(
              message: data['message'],
              senderId: data['senderId'],
              isLocal: false,
            ));
          });
          _scrollToBottom();
        }
      },
      onRequestToSpeakReceived: (data) {
        if (mounted) {
          setState(() {
            if (!_speakRequests.any((req) => req.studentId == data['studentId'])) {
              _speakRequests.add(SpeakRequest(
                studentId: data['studentId'],
                studentName: data['studentName'],
                socketId: data['socketId'],
              ));
            }
          });
        }
      },
      onOfferReceived: (data) {},
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
    // ... (Dispose logic remains the same)
        _localRenderer.dispose();
    _localStream?.getTracks().forEach((track) => track.stop());
    _peerConnection?.close();
    _classroomService.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ... (Chat and Speak Requests functions remain the same)
    void _sendMessage() {
    final message = _chatController.text.trim();
    if (message.isNotEmpty) {
      _classroomService.sendChatMessage(widget.classData['class_id'], message);
      setState(() {
        _chatMessages.add(ChatMessage(message: message, senderId: 'me', isLocal: true));
      });
      _chatController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _showSpeakRequests() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: _speakRequests.length,
          itemBuilder: (context, index) {
            final request = _speakRequests[index];
            return ListTile(
              title: Text(request.studentName),
              trailing: ElevatedButton(
                child: const Text('سماح'),
                onPressed: () {
                  print('Allowing ${request.studentName} to speak.');
                  Navigator.pop(context);
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleBroadcast() async {
    if (_isBroadcasting) {
      await _stopBroadcast();
      return;
    }
    await _startBroadcast();
  }

  Future<void> _startBroadcast({bool screenSharing = false}) async {
    try {
      if (screenSharing) {
        _localStream = await navigator.mediaDevices.getDisplayMedia({'video': true, 'audio': true});
      } else {
        _localStream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});
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

      setState(() {
        _isBroadcasting = true;
        _isScreenSharing = screenSharing;
      });
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
      setState(() {
        _isBroadcasting = false;
        _isScreenSharing = false;
      });
    } catch (e) {
      print('Error stopping broadcast: $e');
    }
  }

  Future<void> _toggleScreenShare() async {
    if (!_isBroadcasting) return; // Can only share screen if already broadcasting

    if (_isScreenSharing) {
      // Switch back to camera
      await _switchMediaStream(screenSharing: false);
    } else {
      // Switch to screen sharing
      await _switchMediaStream(screenSharing: true);
    }
  }

  Future<void> _switchMediaStream({required bool screenSharing}) async {
    if (_peerConnection == null) return;

    // Stop current stream
    _localStream?.getTracks().forEach((track) => track.stop());

    // Get new stream
    if (screenSharing) {
      _localStream = await navigator.mediaDevices.getDisplayMedia({'video': true, 'audio': true});
    } else {
      _localStream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});
    }

    _localRenderer.srcObject = _localStream;

    // Replace the video track in the existing peer connection
    var videoTrack = _localStream!.getVideoTracks()[0];
    var sender = await _peerConnection!.getSenders().firstWhere((s) => s.track?.kind == 'video');
    await sender.replaceTrack(videoTrack);

    setState(() => _isScreenSharing = screenSharing);
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers, {});

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
          // Video View
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: _isBroadcasting
                  ? RTCVideoView(_localRenderer, mirror: _isScreenSharing ? false : true)
                  : const Center(
                      child: Text('البث متوقف', style: TextStyle(color: Colors.white)),
                    ),
            ),
          ),
          // Chat View
          Expanded(
            flex: 1,
            child: Column(
              // ... (Chat UI remains the same)
                  children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = _chatMessages[index];
                      return ListTile(
                        title: Text(msg.message),
                        subtitle: Text(msg.isLocal ? 'أنا' : 'طالب'),
                        tileColor: msg.isLocal ? Colors.blue.withOpacity(0.1) : null,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          decoration: const InputDecoration(
                            hintText: 'اكتب رسالة...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.blueGrey[100],
            child: Text('حالة الخادم: $_serverMessage'),
          ),
          // Controls
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
                _buildControlButton(
                  _isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
                  _isScreenSharing ? 'إيقاف المشاركة' : 'مشاركة الشاشة',
                  _toggleScreenShare,
                ),
                _buildControlButton(
                  Icons.pan_tool,
                  'طلبات المداخلة (${_speakRequests.length})',
                  _showSpeakRequests,
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
