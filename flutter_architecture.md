# Flutter Frontend Architecture - المعهد الأول

## Architecture Overview

### Offline-First Design Pattern
The application follows an offline-first architecture ensuring functionality even with poor or no internet connectivity.

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   UI Layer      │    │   State Mgmt    │    │   Data Layer    │
│   (Screens)     │◄──►│   (Riverpod)    │◄──►│   (Repository)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Local Cache   │    │   Sync Service  │
                       │   (Hive/SQLite) │    │   (Background)  │
                       └─────────────────┘    └─────────────────┘
```

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_theme.dart
│   │   └── app_strings.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   ├── api_constants.dart
│   │   ├── dio_client.dart
│   │   └── network_info.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── helpers.dart
│   │   └── extensions.dart
│   └── services/
│       ├── local_storage.dart
│       ├── sync_service.dart
│       └── notification_service.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   ├── teacher/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── student/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── admin/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── shared/
    ├── widgets/
    ├── utils/
    └── services/
```

## Core Features Implementation

### 1. Offline-First Data Management

#### Local Storage Service
```dart
class LocalStorageService {
  static const String _userBox = 'userBox';
  static const String _classBox = 'classBox';
  static const String _chatBox = 'chatBox';
  
  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(ClassModelAdapter());
    Hive.registerAdapter(ChatMessageAdapter());
    
    await Hive.openBox<UserModel>(_userBox);
    await Hive.openBox<ClassModel>(_classBox);
    await Hive.openBox<ChatMessage>(_chatBox);
  }
  
  // CRUD operations with offline support
  Future<void> saveUser(UserModel user) async {
    await Hive.box<UserModel>(_userBox).put(user.id, user);
  }
  
  UserModel? getUser(String id) {
    return Hive.box<UserModel>(_userBox).get(id);
  }
}
```

#### Sync Service
```dart
class SyncService {
  final LocalStorageService _localStorage;
  final ApiService _apiService;
  final NetworkInfo _networkInfo;
  
  Future<void> syncData() async {
    if (!await _networkInfo.isConnected) return;
    
    await Future.wait([
      syncUsers(),
      syncClasses(),
      syncChatMessages(),
      syncAttendance(),
    ]);
  }
  
  Future<void> syncChatMessages() async {
    final pendingMessages = _localStorage.getPendingMessages();
    for (final message in pendingMessages) {
      try {
        await _apiService.sendMessage(message);
        await _localStorage.markMessageAsSynced(message.id);
      } catch (e) {
        print('Failed to sync message: $e');
      }
    }
  }
}
```

### 2. Real-time Communication (WebRTC)

#### WebRTC Service
```dart
class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final _remoteStreams = StreamController<MediaStream>.broadcast();
  
  Future<void> initialize() async {
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    });
    
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      _remoteStreams.add(event.streams[0]);
    };
  }
  
  Future<void> startCamera() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'video': true,
      'audio': true,
    });
    
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
  }
  
  Future<void> startScreenShare() async {
    _localStream = await navigator.mediaDevices.getDisplayMedia({
      'video': true,
      'audio': true,
    });
    
    // Replace camera track with screen track
    final sender = _peerConnection!.getSenders().firstWhere(
      (s) => s.track?.kind == 'video'
    );
    await sender.replaceTrack(_localStream!.getVideoTracks()[0]);
  }
}
```

#### Signaling Service
```dart
class SignalingService {
  final Socket _socket;
  
  void handleTeacherControls() {
    _socket.on('studentRequestToSpeak', (data) {
      // Show teacher notification about student request
      final studentName = data['studentName'];
      final studentId = data['studentId'];
      
      _notificationService.showNotification(
        title: 'طلب مداخلة',
        body: 'الطالب $studentName يريد التحدث',
        actions: [
          NotificationAction('allow', 'السماح'),
          NotificationAction('deny', 'رفض'),
        ],
      );
    });
  }
  
  void requestToSpeak(String sessionId) {
    _socket.emit('requestToSpeak', {
      'sessionId': sessionId,
      'studentId': _authService.currentUser?.id,
    });
  }
}
```

### 3. Drawing Tools Implementation

#### Drawing Canvas Widget
```dart
class DrawingCanvas extends StatefulWidget {
  final Function(List<DrawingPoint>) onDrawingUpdated;
  
  @override
  _DrawingCanvasState createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<DrawingPoint> drawingPoints = [];
  Color selectedColor = Colors.red;
  double strokeWidth = 3.0;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          drawingPoints.add(DrawingPoint(
            point: details.localPosition,
            paint: Paint()
              ..color = selectedColor
              ..strokeWidth = strokeWidth
              ..strokeCap = StrokeCap.round,
          ));
        });
      },
      onPanUpdate: (details) {
        setState(() {
          drawingPoints.add(DrawingPoint(
            point: details.localPosition,
            paint: Paint()
              ..color = selectedColor
              ..strokeWidth = strokeWidth
              ..strokeCap = StrokeCap.round,
          ));
        });
        widget.onDrawingUpdated(drawingPoints);
      },
      child: CustomPaint(
        painter: DrawingPainter(drawingPoints),
        size: Size.infinite,
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> drawingPoints;
  
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < drawingPoints.length - 1; i++) {
      if (drawingPoints[i].point != null && drawingPoints[i + 1].point != null) {
        canvas.drawLine(
          drawingPoints[i].point!,
          drawingPoints[i + 1].point!,
          drawingPoints[i].paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

### 4. Recording System

#### Recording Service
```dart
class RecordingService {
  MediaRecorder? _mediaRecorder;
  bool _isRecording = false;
  
  Future<void> startRecording(MediaStream stream) async {
    if (_isRecording) return;
    
    _mediaRecorder = MediaRecorder();
    
    await _mediaRecorder!.start(
      streamId: stream.id,
      mimeType: 'video/webm',
    );
    
    _isRecording = true;
    
    // Start chunk upload for large recordings
    _startChunkUpload();
  }
  
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    
    final recordingData = await _mediaRecorder!.stop();
    _isRecording = false;
    
    // Upload complete recording
    await _uploadRecording(recordingData);
  }
  
  Future<void> _uploadRecording(Uint8List data) async {
    final formData = FormData();
    formData.files.add(MapEntry(
      'recording',
      MultipartFile.fromBytes(
        data,
        filename: 'session_${DateTime.now().millisecondsSinceEpoch}.webm',
      ),
    ));
    
    await _apiService.uploadRecording(formData);
  }
}
```

### 5. State Management with Riverpod

#### Teacher State Provider
```dart
final teacherProvider = StateNotifierProvider<TeacherNotifier, TeacherState>((ref) {
  return TeacherNotifier(
    teacherRepository: ref.watch(teacherRepositoryProvider),
    localStorage: ref.watch(localStorageProvider),
  );
});

class TeacherNotifier extends StateNotifier<TeacherState> {
  final TeacherRepository _teacherRepository;
  final LocalStorageService _localStorage;
  
  Future<void> loadClasses() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Try to load from local storage first
      final localClasses = await _localStorage.getTeacherClasses();
      if (localClasses.isNotEmpty) {
        state = state.copyWith(classes: localClasses);
      }
      
      // Then sync with server
      final remoteClasses = await _teacherRepository.getClasses();
      await _localStorage.saveTeacherClasses(remoteClasses);
      
      state = state.copyWith(
        classes: remoteClasses,
        isLoading: false,
        lastSync: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
}
```

### 6. UI Components

#### Custom Video Player Widget
```dart
class VideoPlayerWidget extends StatefulWidget {
  final MediaStream stream;
  final bool isLocal;
  
  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  RTCVideoRenderer? _renderer;
  
  @override
  void initState() {
    super.initState();
    _initializeRenderer();
  }
  
  Future<void> _initializeRenderer() async {
    _renderer = RTCVideoRenderer();
    await _renderer!.initialize();
    _renderer!.srcObject = widget.stream;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: RTCVideoView(
        _renderer!,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        mirror: widget.isLocal,
      ),
    );
  }
}
```

### 7. Chat System with Offline Support

#### Chat Provider
```dart
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(
    chatRepository: ref.watch(chatRepositoryProvider),
    localStorage: ref.watch(localStorageProvider),
  );
});

class ChatNotifier extends StateNotifier<ChatState> {
  Future<void> sendMessage(String content) async {
    final message = ChatMessage(
      id: generateId(),
      senderId: currentUser.id,
      content: content,
      timestamp: DateTime.now(),
      isPending: true,
    );
    
    // Add to local storage immediately
    await _localStorage.saveMessage(message);
    state = state.copyWith(
      messages: [...state.messages, message],
    );
    
    // Try to send to server
    try {
      await _chatRepository.sendMessage(message);
      final updatedMessage = message.copyWith(isPending: false);
      await _localStorage.updateMessage(updatedMessage);
      
      state = state.copyWith(
        messages: state.messages.map((m) => 
          m.id == message.id ? updatedMessage : m
        ).toList(),
      );
    } catch (e) {
      // Will retry on next sync
      print('Failed to send message: $e');
    }
  }
}
```

## Key Features Implementation

### 1. Offline-First Strategy
- All critical data cached locally using Hive
- Background sync service for data synchronization
- Conflict resolution for simultaneous edits
- Progressive loading with skeleton screens

### 2. Real-time Communication
- WebRTC for video/audio streaming
- Socket.io for signaling and chat
- Efficient connection management
- Automatic reconnection handling

### 3. Security Measures
- Encrypted local storage
- Secure API communication
- Input validation and sanitization
- Role-based access control

### 4. Performance Optimization
- Lazy loading of components
- Image caching and compression
- Efficient state management
- Memory leak prevention

This architecture ensures a robust, scalable, and user-friendly educational platform that works seamlessly even in challenging network conditions.